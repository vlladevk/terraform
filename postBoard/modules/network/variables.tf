variable "common_tags" {
  type = map(string)
}

variable "db_subnet_cidr_blocks" {
  type = list(string)
}

variable "default_route_cidr_block" {
  type = string
}

variable "project_name" {
  type = string
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
}

variable "vpc_cidr_block" {
  type = string
}
