provider "aws" {
  region = var.aws_region
}

# Generate secure random password
resource "random_password" "db_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "axialy-rds-sg-"
  description = "Security group for Axialy RDS instance"

  ingress {
    description = "MySQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Note: Restrict this in production
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "axialy-rds-security-group"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "axialy" {
  identifier     = var.db_identifier
  engine         = "mysql"
  engine_version = "8.0.35"

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "axialy"
  username = var.admin_default_user
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # For initial setup, make it publicly accessible
  # Change to false and use VPC peering/VPN in production
  publicly_accessible = true

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  skip_final_snapshot = true  # Set to false in production
  deletion_protection = false  # Set to true in production

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name        = "axialy-database"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Store credentials in SSM Parameter Store
resource "aws_ssm_parameter" "db_host" {
  name  = "/axialy/database/host"
  type  = "String"
  value = aws_db_instance.axialy.address

  tags = {
    Project = "Axialy AI Platform"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/axialy/database/password"
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Project = "Axialy AI Platform"
  }
}
