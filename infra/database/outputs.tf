output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.axialy.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.axialy.port
}

output "db_admin_user" {
  description = "Database admin username"
  value       = aws_db_instance.axialy.username
}

output "db_admin_password" {
  description = "Database admin password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.axialy.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "kms_key_id" {
  description = "ID of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.id
}

output "ssm_parameter_names" {
  description = "Names of SSM parameters containing database credentials"
  value = {
    host     = aws_ssm_parameter.db_host.name
    port     = aws_ssm_parameter.db_port.name
    user     = aws_ssm_parameter.db_user.name
    password = aws_ssm_parameter.db_password.name
  }
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names for RDS logs"
  value = {
    error     = aws_cloudwatch_log_group.rds_error.name
    general   = aws_cloudwatch_log_group.rds_general.name
    slowquery = aws_cloudwatch_log_group.rds_slowquery.name
  }
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.axialy.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.axialy.arn
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.axialy.name
}

output "db_parameter_group_name" {
  description = "The name of the DB parameter group"
  value       = aws_db_parameter_group.axialy.name
}
