data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

data "aws_ecr_repository" "service" {
  for_each = local.ecs_services

  name = each.value.repository_name
}

locals {
  common_tags = {
    Project = var.project_name
  }

  ecs_services = {
    frontend = {
      service_name      = "postboard-frontend"
      repository_name   = "postboard-frontend"
      path_pattern      = null
      priority          = null
      health_check_path = "/"
      environment = {
        POSTS_PAGE_SIZE           = var.posts_page_size
        NOTIFICATIONS_PAGE_SIZE   = var.notifications_page_size
        POSTS_POLLING_INTERVAL_MS = var.posts_polling_interval_ms
      }
    }

    auth = {
      service_name      = "postboard-auth-service"
      repository_name   = "postboard-auth-service"
      path_pattern      = "/api/v1/auth/*"
      priority          = 10
      health_check_path = "/actuator/health"
      environment = {
        APP_NAME              = "postboard-auth-service"
        AWS_REGION            = var.aws_region
        COGNITO_ISSUER_URI    = module.identity.issuer_uri
        COGNITO_USER_POOL_ID  = module.identity.user_pool_id
        COGNITO_CLIENT_ID     = module.identity.client_id
        AUTH_USERS_TABLE      = module.storage.auth_users_table_name
        AUTH_EVENTS_TOPIC_ARN = module.messaging.auth_events_topic_arn
      }
    }

    media = {
      service_name      = "postboard-media-service"
      repository_name   = "postboard-media-service"
      path_pattern      = "/api/v1/media*"
      priority          = 30
      health_check_path = "/actuator/health"
      environment = {
        APP_NAME                   = "postboard-media-service"
        AWS_REGION                 = var.aws_region
        COGNITO_ISSUER_URI         = module.identity.issuer_uri
        MEDIA_S3_BUCKET            = module.storage.media_bucket_name
        MEDIA_S3_OBJECT_KEY_PREFIX = "media/"
        MEDIA_METADATA_TABLE       = module.storage.media_metadata_table_name
        MAX_FILE_SIZE              = var.max_file_size
        MAX_REQUEST_SIZE           = var.max_request_size
      }
    }

    notification = {
      service_name      = "postboard-notification-service"
      repository_name   = "postboard-notification-service"
      path_pattern      = "/api/v1/notifications*"
      priority          = 40
      health_check_path = "/actuator/health"
      environment = {
        APP_NAME                       = "postboard-notification-service"
        AWS_REGION                     = var.aws_region
        COGNITO_ISSUER_URI             = module.identity.issuer_uri
        NOTIFICATIONS_TABLE            = module.storage.notifications_table_name
        NOTIFICATION_SUBSCRIBERS_TABLE = module.storage.notification_subscribers_table_name
        NOTIFICATIONS_TOPIC_ARN        = module.messaging.notifications_topic_arn
        NOTIFICATION_EVENTS_QUEUE_URL  = module.messaging.notification_events_queue_url
      }
    }
  }
}

module "network" {
  source = "./modules/network"

  common_tags               = local.common_tags
  db_subnet_cidr_blocks     = var.db_subnet_cidr_blocks
  default_route_cidr_block  = var.default_route_cidr_block
  project_name              = var.project_name
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
  vpc_cidr_block            = var.vpc_cidr_block
}

module "security" {
  source = "./modules/security"

  common_tags              = local.common_tags
  container_port           = var.container_port
  db_port                  = var.db_port
  default_route_cidr_block = var.default_route_cidr_block
  project_name             = var.project_name
  vpc_id                   = module.network.vpc_id
}

module "identity" {
  source = "./modules/identity"

  aws_region   = var.aws_region
  common_tags  = local.common_tags
  project_name = var.project_name
}

module "messaging" {
  source = "./modules/messaging"

  common_tags                    = local.common_tags
  project_name                   = var.project_name
  sqs_max_receive_count          = var.sqs_max_receive_count
  sqs_visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
}

module "storage" {
  source = "./modules/storage"

  common_tags          = local.common_tags
  db_allocated_storage = var.db_allocated_storage
  db_instance_class    = var.db_instance_class
  db_name              = var.db_name
  db_password          = var.db_password
  db_port              = var.db_port
  db_security_group_id = module.security.db_security_group_id
  db_subnet_ids        = module.network.db_subnet_ids
  db_username          = var.db_username
  project_name         = var.project_name
}

module "load_balancer" {
  source = "./modules/load-balancer"

  common_tags       = local.common_tags
  container_port    = var.container_port
  ecs_services      = local.ecs_services
  project_name      = var.project_name
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  vpc_id            = module.network.vpc_id
}

module "ecs" {
  source = "./modules/ecs"

  aws_region                    = var.aws_region
  alb_dns_name                  = module.load_balancer.alb_dns_name
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  common_tags                   = local.common_tags
  container_port                = var.container_port
  core_api_base_url             = module.core_api.api_base_url
  ecs_cpu_target_value          = var.ecs_cpu_target_value
  ecs_max_capacity              = var.ecs_max_capacity
  ecs_min_capacity              = var.ecs_min_capacity
  ecs_services                  = local.ecs_services
  ecs_task_cpu                  = var.ecs_task_cpu
  ecs_task_memory               = var.ecs_task_memory
  ecr_repository_urls           = { for key, repo in data.aws_ecr_repository.service : key => repo.repository_url }
  execution_role_arn            = data.aws_iam_role.lab_role.arn
  public_subnet_ids             = module.network.public_subnet_ids
  security_group_id             = module.security.ecs_security_group_id
  target_group_arns             = module.load_balancer.target_group_arns
  task_role_arn                 = data.aws_iam_role.lab_role.arn

  depends_on = [module.load_balancer]
}

module "core_lambda" {
  source = "./modules/core-lambda"

  artifact_path                 = var.lambda_artifact_path
  aws_region                    = var.aws_region
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  common_tags                   = local.common_tags
  db_name                       = var.db_name
  db_password                   = var.db_password
  db_port                       = var.db_port
  db_username                   = var.db_username
  lambda_memory_size            = var.lambda_memory_size
  lambda_role_arn               = data.aws_iam_role.lab_role.arn
  lambda_security_group_id      = module.security.lambda_security_group_id
  lambda_subnet_ids             = module.network.public_subnet_ids
  lambda_timeout_seconds        = var.lambda_timeout_seconds
  notification_events_queue_url = module.messaging.notification_events_queue_url
  project_name                  = var.project_name
  rds_address                   = module.storage.core_db_address
}

resource "aws_vpc_endpoint" "sqs" {
  private_dns_enabled = true
  security_group_ids  = [module.security.vpc_endpoint_security_group_id]
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  subnet_ids          = module.network.public_subnet_ids
  vpc_endpoint_type   = "Interface"
  vpc_id              = module.network.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-sqs-endpoint"
  })
}

module "core_api" {
  source = "./modules/core-api"

  client_id             = module.identity.client_id
  common_tags           = local.common_tags
  issuer_uri            = module.identity.issuer_uri
  lambda_function_arns  = module.core_lambda.function_arns
  lambda_function_names = module.core_lambda.function_names
  project_name          = var.project_name
}

module "monitoring" {
  source = "./modules/monitoring"

  aws_region                           = var.aws_region
  common_tags                          = local.common_tags
  dashboard_name                       = "${var.project_name}-dashboard"
  dlq_name                             = module.messaging.notification_events_dlq_name
  ecs_cluster_name                     = module.ecs.cluster_name
  lambda_duration_alarm_threshold_ms   = var.lambda_duration_alarm_threshold_ms
  lambda_error_alarm_threshold         = var.lambda_error_alarm_threshold
  lambda_function_names                = module.core_lambda.function_names
  notification_log_group_name          = module.ecs.log_group_names["notification"]
  notification_service_name            = local.ecs_services.notification.service_name
  project_name                         = var.project_name
  queue_name                           = module.messaging.notification_events_queue_name
  sqs_visible_messages_alarm_threshold = var.sqs_visible_messages_alarm_threshold
}

output "alb_url" {
  value = module.load_balancer.alb_url
}

output "api_base_url" {
  value = module.core_api.api_base_url
}

output "core_api_url" {
  value = module.core_api.api_url
}

output "ecr_repository_urls" {
  value = {
    for key, repo in data.aws_ecr_repository.service : key => repo.repository_url
  }
}

output "cognito_user_pool_id" {
  value = module.identity.user_pool_id
}

output "cognito_client_id" {
  value = module.identity.client_id
}

output "core_rds_endpoint" {
  value = module.storage.core_db_endpoint
}
