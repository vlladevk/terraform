variable "client_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "issuer_uri" {
  type = string
}

variable "lambda_function_arns" {
  type = map(string)
}

variable "lambda_function_names" {
  type = map(string)
}

variable "project_name" {
  type = string
}
