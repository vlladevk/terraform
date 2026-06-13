variable "common_tags" {
  type = map(string)
}

variable "container_port" {
  type = number
}

variable "db_port" {
  type = number
}

variable "default_route_cidr_block" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}
