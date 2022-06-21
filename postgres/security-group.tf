resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "acesso-ssh"
  vpc_id = aws_vpc.vpc_database_postgres.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cdirs_acesso_remoto
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = var.cdirs_acesso_remoto
  }

  tags = {
    Name = "ssh"
  }
}