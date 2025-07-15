provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_vpc" "axialy" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "axialy-vpc"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_internet_gateway" "axialy" {
  vpc_id = aws_vpc.axialy.id

  tags = {
    Name        = "axialy-igw"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.axialy.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "axialy-private-subnet-${count.index + 1}"
    Type        = "private"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.axialy.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "axialy-public-subnet-${count.index + 1}"
    Type        = "public"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name        = "axialy-nat-eip-${count.index + 1}"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_nat_gateway" "axialy" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "axialy-nat-gateway-${count.index + 1}"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }

  depends_on = [aws_internet_gateway.axialy]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.axialy.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.axialy.id
  }

  tags = {
    Name        = "axialy-public-rt"
    Type        = "public"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.axialy.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.axialy[count.index].id
  }

  tags = {
    Name        = "axialy-private-rt-${count.index + 1}"
    Type        = "private"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "rds" {
  name_prefix = "axialy-rds-sg-"
  description = "Security group for Axialy RDS instance"
  vpc_id      = aws_vpc.axialy.id

  ingress {
    description = "MySQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
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

resource "aws_db_subnet_group" "axialy" {
  name       = "axialy-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "axialy-db-subnet-group"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_db_parameter_group" "axialy" {
  name_prefix = "axialy-mysql8-"
  family      = "mysql8.0"
  description = "Custom parameter group for Axialy MySQL 8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name        = "axialy-db-parameter-group"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for Axialy RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "axialy-rds-kms-key"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/axialy-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_instance" "axialy" {
  identifier             = var.db_identifier
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn
  db_name                = "axialy"
  username               = var.admin_default_user
  password               = random_password.db_password.result
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.axialy.name
  parameter_group_name   = aws_db_parameter_group.axialy.name
  multi_az               = var.multi_az
  publicly_accessible    = false
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  deletion_protection    = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  auto_minor_version_upgrade = true
  apply_immediately          = false
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  tags = {
    Name        = "axialy-database"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/axialy/database/host"
  type  = "String"
  value = aws_db_instance.axialy.address

  tags = {
    Name        = "axialy-db-host"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/axialy/database/port"
  type  = "String"
  value = aws_db_instance.axialy.port

  tags = {
    Name        = "axialy-db-port"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/axialy/database/user"
  type  = "String"
  value = aws_db_instance.axialy.username

  tags = {
    Name        = "axialy-db-user"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/axialy/database/password"
  type  = "SecureString"
  value = random_password.db_password.result

  tags = {
    Name        = "axialy-db-password"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "rds_error" {
  name              = "/aws/rds/instance/${var.db_identifier}/error"
  retention_in_days = 30

  tags = {
    Name        = "axialy-rds-error-logs"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "rds_general" {
  name              = "/aws/rds/instance/${var.db_identifier}/general"
  retention_in_days = 7

  tags = {
    Name        = "axialy-rds-general-logs"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "rds_slowquery" {
  name              = "/aws/rds/instance/${var.db_identifier}/slowquery"
  retention_in_days = 7

  tags = {
    Name        = "axialy-rds-slowquery-logs"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "axialy-database-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors database CPU utilization"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.axialy.id
  }

  tags = {
    Name        = "axialy-database-cpu-alarm"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "axialy-database-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648
  alarm_description   = "This metric monitors database free storage space"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.axialy.id
  }

  tags = {
    Name        = "axialy-database-storage-alarm"
    Project     = "Axialy AI Platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
