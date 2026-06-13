variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "postboard"
}

variable "lab_role_name" {
  type    = string
  default = "LabRole"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "db_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "default_route_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "ecs_task_cpu" {
  type    = number
  default = 512
}

variable "ecs_task_memory" {
  type    = number
  default = 1024
}

variable "ecs_min_capacity" {
  type    = number
  default = 2
}

variable "ecs_max_capacity" {
  type    = number
  default = 4
}

variable "ecs_cpu_target_value" {
  type    = number
  default = 60
}

variable "db_name" {
  type    = string
  default = "postboarddb"
}

variable "db_username" {
  type    = string
  default = "pb_admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "cloudwatch_log_retention_days" {
  type    = number
  default = 7
}

variable "lambda_artifact_path" {
  type    = string
}

variable "lambda_memory_size" {
  type    = number
  default = 1024
}

variable "lambda_timeout_seconds" {
  type    = number
  default = 30
}

variable "sqs_visibility_timeout_seconds" {
  type    = number
  default = 60
}

variable "sqs_max_receive_count" {
  type    = number
  default = 5
}

variable "lambda_error_alarm_threshold" {
  type    = number
  default = 1
}

variable "lambda_duration_alarm_threshold_ms" {
  type    = number
  default = 10000
}

variable "sqs_visible_messages_alarm_threshold" {
  type    = number
  default = 25
}

variable "posts_page_size" {
  type    = string
  default = "8"
}

variable "notifications_page_size" {
  type    = string
  default = "20"
}

variable "posts_polling_interval_ms" {
  type    = string
  default = "5000"
}

variable "max_file_size" {
  type    = string
  default = "5MB"
}

variable "max_request_size" {
  type    = string
  default = "5MB"
}
