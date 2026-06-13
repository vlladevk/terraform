resource "aws_lb" "public" {
  internal           = false
  load_balancer_type = "application"
  name               = "${var.project_name}-alb"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-alb"
  })
}

resource "aws_lb_target_group" "service" {
  for_each = var.ecs_services

  name        = "${var.project_name}-${each.key}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = each.value.health_check_path
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${each.key}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.service["frontend"].arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "api" {
  for_each = {
    for key, service in var.ecs_services : key => service
    if service.path_pattern != null
  }

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    target_group_arn = aws_lb_target_group.service[each.key].arn
    type             = "forward"
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}
