resource "aws_security_group" "alb" {
  description = "Allow public HTTP traffic to PostBoard ALB"
  name        = "${var.project_name}-alb-sg"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = [var.default_route_cidr_block]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  egress {
    cidr_blocks = [var.default_route_cidr_block]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

resource "aws_security_group" "ecs" {
  description = "Allow ALB traffic to Fargate tasks"
  name        = "${var.project_name}-ecs-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    to_port         = var.container_port
  }

  egress {
    cidr_blocks = [var.default_route_cidr_block]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ecs-sg"
  })
}

resource "aws_security_group" "lambda" {
  description = "Allow core Lambda functions to reach RDS and VPC endpoints"
  name        = "${var.project_name}-lambda-sg"
  vpc_id      = var.vpc_id

  egress {
    cidr_blocks = [var.default_route_cidr_block]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-lambda-sg"
  })
}

resource "aws_security_group" "vpc_endpoint" {
  description = "Allow application HTTPS traffic to AWS interface endpoints"
  name        = "${var.project_name}-endpoint-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id, aws_security_group.lambda.id]
    to_port         = 443
  }

  egress {
    cidr_blocks = [var.default_route_cidr_block]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-endpoint-sg"
  })
}

resource "aws_security_group" "db" {
  description = "Allow PostgreSQL from Fargate tasks and core Lambda functions"
  name        = "${var.project_name}-db-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id, aws_security_group.lambda.id]
    to_port         = var.db_port
  }

  egress {
    cidr_blocks = [var.default_route_cidr_block]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-sg"
  })
}
