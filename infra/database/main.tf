terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "db" {
  name        = "${var.db_instance_identifier}-sg"
  description = "Axialy RDS MySQL access"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "master" {
  length  = 20
  special = false
}

resource "aws_db_instance" "axialy" {
  identifier             = var.db_instance_identifier
  instance_class         = var.db_instance_class
  engine                 = "mysql"
  engine_version         = "8.0"
  allocated_storage      = var.allocated_storage
  username               = "axialy_admin"
  password               = random_password.master.result
  db_name                = "axialy_admin"
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  apply_immediately      = true
}
