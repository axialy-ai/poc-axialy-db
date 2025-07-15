output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.axialy.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.axialy.port
}

output "db_admin_user" {
  description = "Admin username"
  value       = aws_db_instance.axialy.username
}

output "db_admin_password" {
  description = "Admin password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.axialy.id
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}
