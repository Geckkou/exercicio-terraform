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
  region = "us-east-1"
}

#EC2
resource "aws_instance" "dev" {
  count = 2
  ami = var.amis["ubuntu"]
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_postgres_a.id
  key_name = var.key_name
  tags = {
    Name = "dev${count.index}"
  }
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
}

resource "aws_instance" "postgres" {
  ami = var.amis["ubuntu"]
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_postgres_a.id
  key_name = var.key_name
  user_data = file("configure.sh")
  tags = {
    Name = "Postgres"
  }
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  depends_on = [aws_db_instance.postgres_db]
}

#VPC
resource "aws_vpc" "vpc_database_postgres" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "database-vpc"
  }
}

#SUBNET
resource "aws_subnet" "public_subnet_postgres_a" {
  vpc_id = aws_vpc.vpc_database_postgres.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_postgres_b" {
  vpc_id = aws_vpc.vpc_database_postgres.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

#SUBNET DB GROUP
resource "aws_db_subnet_group" "db_subnet_postgres" {
  name = "dbsubnet_postgres"
  subnet_ids = ["${aws_subnet.public_subnet_postgres_a.id}", "${aws_subnet.private_subnet_postgres_b.id}"]

  tags = {
    Name = "My db postgres subnet group"
  }
}

#DATABASE
resource "aws_db_instance" "postgres_db" {
  allocated_storage = 10
  engine = "postgres"
  engine_version = "13.4"
  instance_class = "db.t3.micro"
  db_name = "postgres_terraform"
  username = "db_user"
  password = var.password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_postgres.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  skip_final_snapshot = true
}





# Internet gateway
resource "aws_internet_gateway" "internet_gateway_postgres" {
  vpc_id = aws_vpc.vpc_database_postgres.id

  tags = {
    Name = "internet-gateway"
  }
}

# Route table with target as internet gateway
resource "aws_route_table" "postgres_route_table" {
  vpc_id = aws_vpc.vpc_database_postgres.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_postgres.id
  }

  tags = {
    Name = "postgres-route-table"
  }
} 

# Associate route table to public subnet
resource "aws_route_table_association" "associate_routable_to_public_subnet" {
  subnet_id = aws_subnet.public_subnet_postgres_a.id
  route_table_id = aws_route_table.postgres_route_table.id
}

# Elastic ip
resource "aws_eip" "elastic-ip" {
  vpc = true
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id = aws_subnet.public_subnet_postgres_a.id

  tags = {
    Name = "nat-gateway"
  }
}