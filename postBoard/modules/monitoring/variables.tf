variable "aws_region" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "dashboard_name" {
  type = string
}

variable "dlq_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "lambda_duration_alarm_threshold_ms" {
  type = number
}

variable "lambda_error_alarm_threshold" {
  type = number
}

variable "lambda_function_names" {
  type = map(string)
}

variable "notification_log_group_name" {
  type = string
}

variable "notification_service_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "queue_name" {
  type = string
}

variable "sqs_visible_messages_alarm_threshold" {
  type = number
}
