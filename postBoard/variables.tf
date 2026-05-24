variable "bucket_name_prefix" {
  type    = string
  default = "post-board-bucket"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "post-board"
}

variable "bucket_tag_name" {
  type    = string
  default = "post-board-bucket"
}

variable "vpc_tag_name" {
  type    = string
  default = "post-board-vpc"
}

variable "internet_gateway_tag_name" {
  type    = string
  default = "main-igw"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "edge_public_a_cidr_block" {
  type    = string
  default = "10.0.1.0/24"
}

variable "edge_public_a_tag_name" {
  type    = string
  default = "edge-public-a"
}

variable "edge_public_b_cidr_block" {
  type    = string
  default = "10.0.2.0/24"
}

variable "edge_public_b_tag_name" {
  type    = string
  default = "edge-public-b"
}

variable "app_private_a_cidr_block" {
  type    = string
  default = "10.0.10.0/24"
}

variable "app_private_a_tag_name" {
  type    = string
  default = "app-private-a"
}

variable "app_private_b_cidr_block" {
  type    = string
  default = "10.0.11.0/24"
}

variable "app_private_b_tag_name" {
  type    = string
  default = "app-private-b"
}

variable "db_private_a_cidr_block" {
  type    = string
  default = "10.0.20.0/24"
}

variable "db_private_a_tag_name" {
  type    = string
  default = "db-private-a"
}

variable "db_private_b_cidr_block" {
  type    = string
  default = "10.0.21.0/24"
}

variable "db_private_b_tag_name" {
  type    = string
  default = "db-private-b"
}

variable "db_subnet_group_name" {
  type    = string
  default = "db-private-subnet-group"
}

variable "db_subnet_group_tag_name" {
  type    = string
  default = "RDS private subnet group"
}

variable "public_route_table_tag_name" {
  type    = string
  default = "public-route-table"
}

variable "nat_eip_tag_name" {
  type    = string
  default = "main-nat-eip"
}

variable "nat_gateway_tag_name" {
  type    = string
  default = "main-nat-gateway"
}

variable "app_private_route_table_tag_name" {
  type    = string
  default = "app-private-route-table"
}

variable "db_private_route_table_tag_name" {
  type    = string
  default = "db-private-route-table"
}

variable "public_ingress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "default_route_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}

variable "public_alb_ports" {
  type    = list(number)
  default = [80, 443]
}

variable "instance_http_port" {
  type    = number
  default = 80
}

variable "database_port" {
  type    = number
  default = 5432
}

variable "domain_name" {
  type    = string
}

variable "certificate_tag_name" {
  type    = string
  default = "vlladevk-me-cert"
}

variable "backend_public_url" {
  type    = string
}

variable "backend_bundle_path" {
  type    = string
  default = "post-board-backend.zip"
}

variable "frontend_bundle_path" {
  type    = string
  default = "post-board-frontend.zip"
}

variable "backend_bundle_key" {
  type    = string
  default = "deploy/backend-app.zip"
}

variable "frontend_bundle_key" {
  type    = string
  default = "deploy/frontend-app.zip"
}

variable "frontend_public_url" {
  type    = string
}

variable "eb_solution_stack_name" {
  type    = string
  default = "64bit Amazon Linux 2023 v4.12.1 running Docker"
}

variable "backend_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "frontend_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "eb_instance_profile" {
  type    = string
  default = "LabInstanceProfile"
}

variable "eb_service_role" {
  type    = string
  default = "LabRole"
}

variable "backend_container_port" {
  type    = string
  default = "8080"
}

variable "frontend_container_port" {
  type    = string
  default = "8080"
}

variable "eb_process_port" {
  type    = string
  default = "80"
}

variable "backend_health_check_path" {
  type    = string
  default = "/actuator/health"
}

variable "frontend_health_check_path" {
  type    = string
  default = "/"
}

variable "db_name" {
  type    = string
  default = "postboarddb"
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "18.3"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 10
}

variable "db_max_allocated_storage" {
  type    = number
  default = 20
}

variable "db_username" {
  type    = string
  default = "pb_admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_parameter_group_name" {
  type    = string
  default = "default.postgres18"
}

variable "cognito_domain_prefix" {
  type    = string
}

variable "cognito_user_pool_name" {
  type    = string
  default = "post-board-user-pool"
}

variable "cognito_user_pool_tag_name" {
  type    = string
  default = "post-board-cognito-pool"
}

variable "cognito_client_name" {
  type    = string
  default = "post-board-app-client"
}

variable "cognito_oauth_scopes" {
  type    = list(string)
  default = ["openid", "email", "profile"]
}

variable "frontend_cognito_scope" {
  type    = string
  default = "openid email profile"
}

variable "max_file_size" {
  type    = string
  default = "10MB"
}

variable "max_request_size" {
  type    = string
  default = "10MB"
}

variable "page_default_size" {
  type    = string
  default = "20"
}

variable "page_max_size" {
  type    = string
  default = "100"
}

variable "swagger_ui_path" {
  type    = string
  default = "/swagger-ui.html"
}

variable "s3_endpoint" {
  type    = string
  default = ""
}

variable "s3_object_key_prefix" {
  type    = string
  default = "uploads/"
}

variable "s3_path_style_access" {
  type    = string
  default = "false"
}

variable "frontend_api_base_url" {
  type    = string
  default = "/api"
}

variable "posts_page_size" {
  type    = string
  default = "8"
}

variable "posts_polling_interval_ms" {
  type    = string
  default = "5000"
}

variable "posts_max_sync_pages" {
  type    = string
  default = "5"
}

variable "cloudwatch_log_retention_days" {
  type    = string
  default = "7"
}

variable "cloudwatch_alarm_period_seconds" {
  type    = number
  default = 300
}

variable "backend_alb_5xx_alarm_evaluation_periods" {
  type    = number
  default = 1
}

variable "backend_alb_5xx_alarm_threshold" {
  type    = number
  default = 5
}

variable "rds_cpu_alarm_evaluation_periods" {
  type    = number
  default = 2
}

variable "rds_cpu_alarm_threshold" {
  type    = number
  default = 80
}
