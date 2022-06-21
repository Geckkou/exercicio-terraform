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

resource "aws_instance" "docker" {
  ami = var.amis["ubuntu"]
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  user_data = file("configure_docker.sh")
    
  tags = {
    Name = "Docker"
  }
}
