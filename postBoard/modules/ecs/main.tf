resource "aws_cloudwatch_log_group" "service" {
  for_each = var.ecs_services

  name              = "/ecs/${each.value.service_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.common_tags
}

resource "aws_ecs_cluster" "main" {
  name = "postboard-cluster"

  tags = var.common_tags
}

resource "aws_ecs_task_definition" "service" {
  for_each = var.ecs_services

  container_definitions = jsonencode([
    {
      name      = each.value.service_name
      image     = "${var.ecr_repository_urls[each.key]}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for name, value in merge(
          each.value.environment,
          each.key == "frontend" ? {
            APP_API_BASE_URL      = "http://${var.alb_dns_name}/api/v1"
            APP_CORE_API_BASE_URL = var.core_api_base_url
          } : {}
          ) : {
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
  cpu                      = var.ecs_task_cpu
  execution_role_arn       = var.execution_role_arn
  family                   = each.value.service_name
  memory                   = var.ecs_task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = var.task_role_arn

  tags = var.common_tags
}

resource "aws_ecs_service" "service" {
  for_each = var.ecs_services

  cluster         = aws_ecs_cluster.main.id
  desired_count   = var.ecs_min_capacity
  launch_type     = "FARGATE"
  name            = each.value.service_name
  task_definition = aws_ecs_task_definition.service[each.key].arn

  load_balancer {
    container_name   = each.value.service_name
    container_port   = var.container_port
    target_group_arn = var.target_group_arns[each.key]
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [var.security_group_id]
    subnets          = var.public_subnet_ids
  }

  tags = var.common_tags
}

resource "aws_appautoscaling_target" "ecs" {
  for_each = var.ecs_services

  max_capacity       = var.ecs_max_capacity
  min_capacity       = var.ecs_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.service[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  for_each = var.ecs_services

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
