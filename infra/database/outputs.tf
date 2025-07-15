output "db_host" {
  value = aws_db_instance.axialy.address
}

output "db_port" {
  value = aws_db_instance.axialy.port
}

output "db_user" {
  value = "axialy_admin"
}

output "db_pass" {
  value     = random_password.master.result
  sensitive = true
}
