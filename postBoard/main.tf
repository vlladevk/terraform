terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

data "aws_ecr_repository" "service" {
  for_each = local.services

  name = each.value.repository_name
}

locals {
  common_tags = {
    Project = var.project_name
  }

  cognito_issuer_uri = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"

  services = {
    frontend = {
      service_name      = "postboard-frontend"
      repository_name   = "postboard-frontend"
      path_pattern      = null
      priority          = null
      health_check_path = "/"
      environment = {
        APP_API_BASE_URL          = "http://${aws_lb.public.dns_name}/api/v1"
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
        COGNITO_ISSUER_URI    = local.cognito_issuer_uri
        COGNITO_USER_POOL_ID  = aws_cognito_user_pool.users.id
        COGNITO_CLIENT_ID     = aws_cognito_user_pool_client.app.id
        AUTH_USERS_TABLE      = aws_dynamodb_table.auth_users.name
        AUTH_EVENTS_TOPIC_ARN = aws_sns_topic.auth_events.arn
      }
    }

    core = {
      service_name      = "postboard-core-service"
      repository_name   = "postboard-core-service"
      path_pattern      = "/api/v1/posts*"
      priority          = 20
      health_check_path = "/actuator/health"
      environment = {
        APP_NAME              = "postboard-core-service"
        AWS_REGION            = var.aws_region
        DB_URL                = "jdbc:postgresql://${aws_db_instance.core.address}:${var.db_port}/${var.db_name}"
        DB_USERNAME           = aws_db_instance.core.username
        DB_PASSWORD           = var.db_password
        COGNITO_ISSUER_URI    = local.cognito_issuer_uri
        CORE_EVENTS_TOPIC_ARN = aws_sns_topic.core_events.arn
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
        COGNITO_ISSUER_URI         = local.cognito_issuer_uri
        MEDIA_S3_BUCKET            = aws_s3_bucket.media.bucket
        MEDIA_S3_OBJECT_KEY_PREFIX = "media/"
        MEDIA_METADATA_TABLE       = aws_dynamodb_table.media_metadata.name
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
        COGNITO_ISSUER_URI             = local.cognito_issuer_uri
        NOTIFICATIONS_TABLE            = aws_dynamodb_table.notifications.name
        NOTIFICATION_SUBSCRIBERS_TABLE = aws_dynamodb_table.notification_subscribers.name
        NOTIFICATIONS_TOPIC_ARN        = aws_sns_topic.notifications.arn
        NOTIFICATION_EVENTS_QUEUE_URL  = aws_sqs_queue.notification_events.url
      }
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-${count.index + 1}"
  })
}

resource "aws_subnet" "db" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-${count.index + 1}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.default_route_cidr_block
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-rt"
  })
}

resource "aws_route_table_association" "db" {
  count = 2

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow public HTTP traffic to PostBoard ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [var.default_route_cidr_block]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [var.default_route_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow ALB traffic to Fargate tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = var.container_port
    to_port   = var.container_port
    protocol  = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [var.default_route_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecs-sg"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Allow PostgreSQL from Fargate tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = var.db_port
    to_port   = var.db_port
    protocol  = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [var.default_route_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-sg"
  })
}

resource "aws_cloudwatch_log_group" "service" {
  for_each = local.services

  name              = "/ecs/${each.value.service_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = local.common_tags
}

resource "aws_lb" "public" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb"
  })
}

resource "aws_lb_target_group" "service" {
  for_each = local.services

  name        = "${var.project_name}-${each.key}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service["frontend"].arn
  }
}

resource "aws_lb_listener_rule" "api" {
  for_each = {
    for key, service in local.services : key => service
    if service.path_pattern != null
  }

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}

resource "aws_cognito_user_pool" "users" {
  name = "${var.project_name}-users"

  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  tags = local.common_tags
}

resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.project_name}-app-client"
  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

resource "aws_db_subnet_group" "core" {
  name       = "${var.project_name}-core-db-subnets"
  subnet_ids = aws_subnet.db[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-core-db-subnets"
  })
}

resource "aws_db_instance" "core" {
  identifier              = "${var.project_name}-core-db"
  engine                  = "postgres"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  backup_retention_period = 1
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = var.db_port
  db_subnet_group_name    = aws_db_subnet_group.core.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-core-db"
  })
}

resource "aws_dynamodb_table" "auth_users" {
  name         = "auth_users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "media_metadata" {
  name         = "media_metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "notifications" {
  name         = "notifications"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "recipientUsername"
  range_key    = "id"

  attribute {
    name = "recipientUsername"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "notification_subscribers" {
  name         = "notification_subscribers"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = local.common_tags
}

resource "aws_s3_bucket" "media" {
  bucket_prefix = "${var.project_name}-media-"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-media"
  })
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sns_topic" "core_events" {
  name = "${var.project_name}-core-events"

  tags = local.common_tags
}

resource "aws_sns_topic" "auth_events" {
  name = "${var.project_name}-auth-events"

  tags = local.common_tags
}

resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-notifications"

  tags = local.common_tags
}

resource "aws_sqs_queue" "notification_events" {
  name                       = "${var.project_name}-notification-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  tags = local.common_tags
}

resource "aws_sqs_queue_policy" "notification_events" {
  queue_url = aws_sqs_queue.notification_events.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPostBoardTopicsToSendMessages"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.notification_events.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [
              aws_sns_topic.auth_events.arn,
              aws_sns_topic.core_events.arn
            ]
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "auth_events_to_notification_queue" {
  topic_arn = aws_sns_topic.auth_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notification_events.arn
}

resource "aws_sns_topic_subscription" "core_events_to_notification_queue" {
  topic_arn = aws_sns_topic.core_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notification_events.arn
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "service" {
  for_each = local.services

  family                   = each.value.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = each.value.service_name
      image     = "${data.aws_ecr_repository.service[each.key].repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for name, value in each.value.environment : {
          name  = name
          value = tostring(value)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service[each.key].name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = each.value.service_name
        }
      }
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "service" {
  for_each = local.services

  name            = each.value.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = var.ecs_min_capacity
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service[each.key].arn
    container_name   = each.value.service_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = local.common_tags
}

resource "aws_appautoscaling_target" "ecs" {
  for_each = local.services

  max_capacity       = var.ecs_max_capacity
  min_capacity       = var.ecs_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  for_each = local.services

  name               = "${each.value.service_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.ecs_cpu_target_value

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

output "alb_url" {
  value = "http://${aws_lb.public.dns_name}"
}

output "api_base_url" {
  value = "http://${aws_lb.public.dns_name}/api/v1"
}

output "ecr_repository_urls" {
  value = {
    for key, repo in data.aws_ecr_repository.service : key => repo.repository_url
  }
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.app.id
}

output "core_rds_endpoint" {
  value = aws_db_instance.core.endpoint
}
