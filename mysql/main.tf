terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

#EC2
resource "aws_instance" "instancia" {
    ami = var.amis["ubuntu-east2"]
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet_mysql_a.id
    key_name = var.key_name
    tags = {
      Name = "instancia"
    }
    vpc_security_group_ids = ["${aws_security_group.ssh-us-east-2.id}"]
}

resource "aws_instance" "mysql" { 
  ami = var.amis["ubuntu-east2"]
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_mysql_a.id
  key_name = var.key_name
  user_data = file("configure.sh")
  tags = {
    Name = "mysql"
  }
  vpc_security_group_ids = ["${aws_security_group.ssh-us-east-2.id}"]
  depends_on = [aws_db_instance.mysql_db]
}

#VPC
resource "aws_vpc" "vpc_database_mysql" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "database-vpc"
  }
}

#SUBNET
resource "aws_subnet" "public_subnet_mysql_a" {
  vpc_id = aws_vpc.vpc_database_mysql.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_mysql_b" {
  vpc_id = aws_vpc.vpc_database_mysql.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
}

#SUBNET DB GROUP
resource "aws_db_subnet_group" "db_subnet_mysql" {
  name = "dbsubnet_mysql"
  subnet_ids = ["${aws_subnet.public_subnet_mysql_a.id}", "${aws_subnet.private_subnet_mysql_b.id}"]

  tags = {
    Name = "My db subnet group"
  }
}

#DATABASE
resource "aws_db_instance" "mysql_db" {
  allocated_storage = 10
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  db_name = "mysql_terraform"
  username = "user_test"
  password = var.password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_mysql.id
  vpc_security_group_ids = [aws_security_group.ssh-us-east-2.id]
  skip_final_snapshot = true
}

# Internet gateway
resource "aws_internet_gateway" "internet_gateway_mysql" {
  vpc_id = aws_vpc.vpc_database_mysql.id

  tags = {
    Name = "internet-gateway"
  }
}

# Route table with target as internet gateway
resource "aws_route_table" "mysql_route_table" {
  vpc_id = aws_vpc.vpc_database_mysql.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_mysql.id
  }

  tags = {
    Name = "mysql-route-table"
  }
} 

# Associate route table to public subnet
resource "aws_route_table_association" "associate_routable_to_public_subnet" {
  subnet_id = aws_subnet.public_subnet_mysql_a.id
  route_table_id = aws_route_table.mysql_route_table.id
}

# Elastic ip
resource "aws_eip" "elastic-ip" {
  vpc = true
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id = aws_subnet.public_subnet_mysql_a.id

  tags = {
    Name = "nat-gateway"
  }
}
