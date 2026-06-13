variable "artifact_path" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cloudwatch_log_retention_days" {
  type = number
}

variable "common_tags" {
  type = map(string)
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

variable "db_username" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "lambda_security_group_id" {
  type = string
}

variable "lambda_subnet_ids" {
  type = list(string)
}

variable "notification_events_queue_url" {
  type = string
}

variable "project_name" {
  type = string
}

variable "rds_address" {
  type = string
}
