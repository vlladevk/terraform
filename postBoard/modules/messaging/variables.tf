variable "common_tags" {
  type = map(string)
}

variable "project_name" {
  type = string
}

variable "sqs_max_receive_count" {
  type = number
}

variable "sqs_visibility_timeout_seconds" {
  type = number
}
