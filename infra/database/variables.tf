variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-1"
}

variable "db_identifier" {
  description = "Identifier for the RDS instance"
  type        = string
  default     = "axialy-database-cluster"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "07:00-09:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:09:00-sun:11:00"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "admin_default_user" {
  description = "Default admin username from GitHub secrets"
  type        = string
  default     = "axialy_admin"
}

variable "admin_default_email" {
  description = "Default admin email from GitHub secrets"
  type        = string
  default     = "admin@axialy.ai"
}

variable "smtp_host" {
  description = "SMTP host for email notifications"
  type        = string
  default     = ""
}

variable "smtp_port" {
  description = "SMTP port"
  type        = number
  default     = 587
}

variable "smtp_user" {
  description = "SMTP username"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ec2_elastic_ip_allocation_id" {
  description = "Elastic IP allocation ID for EC2 instances"
  type        = string
  default     = ""
}

variable "ec2_key_pair" {
  description = "EC2 key pair name"
  type        = string
  default     = ""
}
