variable "common_tags" {
  type = map(string)
}

variable "db_allocated_storage" {
  type = number
}

variable "db_instance_class" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type = number
}

variable "db_security_group_id" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "db_username" {
  type = string
}

variable "project_name" {
  type = string
}
