variable "aws_region" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "cloudwatch_log_retention_days" {
  type = number
}

variable "common_tags" {
  type = map(string)
}

variable "container_port" {
  type = number
}

variable "core_api_base_url" {
  type = string
}

variable "ecs_cpu_target_value" {
  type = number
}

variable "ecs_max_capacity" {
  type = number
}

variable "ecs_min_capacity" {
  type = number
}

variable "ecs_services" {
  type = map(object({
    service_name      = string
    repository_name   = string
    path_pattern      = optional(string)
    priority          = optional(number)
    health_check_path = string
    environment       = map(string)
  }))
}

variable "ecs_task_cpu" {
  type = number
}

variable "ecs_task_memory" {
  type = number
}

variable "ecr_repository_urls" {
  type = map(string)
}

variable "execution_role_arn" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "target_group_arns" {
  type = map(string)
}

variable "task_role_arn" {
  type = string
}
