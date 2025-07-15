variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "db_instance_identifier" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}
