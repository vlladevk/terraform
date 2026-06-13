variable "common_tags" {
  type = map(string)
}

variable "container_port" {
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

variable "project_name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}
