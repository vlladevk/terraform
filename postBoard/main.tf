provider "aws" {
  region = var.aws_region
}

locals {
  frontend_public_url_with_slash = "${var.frontend_public_url}/"
  backend_alb_dimension          = replace(aws_elastic_beanstalk_environment.backend_env.load_balancers[0], "/^.*loadbalancer\\//", "")
}

resource "aws_s3_bucket" "post_board_bucket" {
  bucket_prefix = var.bucket_name_prefix
  tags = {
    Name = var.bucket_tag_name
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_tag_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.internet_gateway_tag_name
  }
}

# -------------------------
# Public subnets
# -------------------------

resource "aws_subnet" "edge_public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.edge_public_a_cidr_block
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = var.edge_public_a_tag_name
  }
}

resource "aws_subnet" "edge_public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.edge_public_b_cidr_block
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = var.edge_public_b_tag_name
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.default_route_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.public_route_table_tag_name
  }
}

resource "aws_route_table_association" "edge_public_a_assoc" {
  subnet_id      = aws_subnet.edge_public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "edge_public_b_assoc" {
  subnet_id      = aws_subnet.edge_public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------
# Private app subnets
# -------------------------

resource "aws_subnet" "app_private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_private_a_cidr_block
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = var.app_private_a_tag_name
  }
}

resource "aws_subnet" "app_private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_private_b_cidr_block
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = var.app_private_b_tag_name
  }
}

# -------------------------
# Private db subnets
# -------------------------

resource "aws_subnet" "db_private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_private_a_cidr_block
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = var.db_private_a_tag_name
  }
}

resource "aws_subnet" "db_private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_private_b_cidr_block
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = var.db_private_b_tag_name
  }
}

resource "aws_db_subnet_group" "db_net_group" {
  name       = var.db_subnet_group_name
  subnet_ids = [aws_subnet.db_private_a.id, aws_subnet.db_private_b.id]
  tags = {
    Name = var.db_subnet_group_tag_name
  }
}

# -------------------------
# NAT for private app subnets
# -------------------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = var.nat_eip_tag_name
  }
}

resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.edge_public_a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = var.nat_gateway_tag_name
  }
}

resource "aws_route_table" "app_private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = var.default_route_cidr_block
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }

  tags = {
    Name = var.app_private_route_table_tag_name
  }
}

resource "aws_route_table_association" "app_private_a_assoc" {
  subnet_id      = aws_subnet.app_private_a.id
  route_table_id = aws_route_table.app_private_rt.id
}

resource "aws_route_table_association" "app_private_b_assoc" {
  subnet_id      = aws_subnet.app_private_b.id
  route_table_id = aws_route_table.app_private_rt.id
}

resource "aws_route_table" "db_private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.db_private_route_table_tag_name
  }
}

resource "aws_route_table_association" "db_private_a_assoc" {
  subnet_id      = aws_subnet.db_private_a.id
  route_table_id = aws_route_table.db_private_rt.id
}

resource "aws_route_table_association" "db_private_b_assoc" {
  subnet_id      = aws_subnet.db_private_b.id
  route_table_id = aws_route_table.db_private_rt.id
}

resource "aws_security_group" "backend_alb_sg" {
  name        = "${var.project_name}-backend-alb-sg"
  description = "Allow public HTTP and HTTPS traffic to backend ALB"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.public_alb_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.public_ingress_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.public_ingress_cidr_blocks
  }

  tags = {
    Name = "${var.project_name}-backend-alb-security-group"
  }
}

resource "aws_security_group" "backend_instance_sg" {
  name        = "${var.project_name}-backend-instance-sg"
  description = "Allow HTTP traffic from ALB to backend instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.instance_http_port
    to_port         = var.instance_http_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.public_ingress_cidr_blocks
  }

  tags = {
    Name = "${var.project_name}-backend-instance-security-group"
  }
}

resource "aws_security_group" "frontend_alb_sg" {
  name        = "${var.project_name}-frontend-alb-sg"
  description = "Allow public HTTP and HTTPS traffic to frontend ALB"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.public_alb_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.public_ingress_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.public_ingress_cidr_blocks
  }

  tags = {
    Name = "${var.project_name}-frontend-alb-security-group"
  }
}

resource "aws_security_group" "frontend_instance_sg" {
  name        = "${var.project_name}-frontend-instance-sg"
  description = "Allow HTTP traffic from frontend ALB to frontend instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.instance_http_port
    to_port         = var.instance_http_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.public_ingress_cidr_blocks
  }

  tags = {
    Name = "${var.project_name}-frontend-instance-security-group"
  }
}

resource "aws_security_group" "database_sg" {
  name        = "${var.project_name}-database-sg"
  description = "Allow PostgreSQL traffic from backend instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_instance_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.public_ingress_cidr_blocks
  }

  tags = {
    Name = "${var.project_name}-database-security-group"
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.certificate_tag_name
  }
}

resource "aws_acm_certificate_validation" "cert_wait" {
  certificate_arn = aws_acm_certificate.cert.arn
}

resource "aws_cognito_user_pool" "post_board_users" {
  name = var.cognito_user_pool_name

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = {
    Name = var.cognito_user_pool_tag_name
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = var.cognito_client_name
  user_pool_id = aws_cognito_user_pool.post_board_users.id

  generate_secret     = false
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH"]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = var.cognito_oauth_scopes
  allowed_oauth_flows_user_pool_client = true

  callback_urls = [local.frontend_public_url_with_slash]
  logout_urls   = [local.frontend_public_url_with_slash]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "post_board_domain" {
  domain                = var.cognito_domain_prefix
  managed_login_version = 2
  user_pool_id          = aws_cognito_user_pool.post_board_users.id
}

resource "aws_cognito_managed_login_branding" "post_board_branding" {
  client_id                   = aws_cognito_user_pool_client.client.id
  user_pool_id                = aws_cognito_user_pool.post_board_users.id
  use_cognito_provided_values = true
}

resource "aws_db_instance" "post_board_db" {
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  db_name                = var.db_name
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_net_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]

  parameter_group_name = var.db_parameter_group_name
  skip_final_snapshot  = true
  publicly_accessible  = false
}

resource "aws_elastic_beanstalk_application" "backend_app" {
  name        = "${var.project_name}-backend"
  description = "Backend application for Post Board"
}

resource "aws_s3_object" "backend_bundle" {
  bucket = aws_s3_bucket.post_board_bucket.id
  key    = var.backend_bundle_key
  source = var.backend_bundle_path
  etag   = filemd5(var.backend_bundle_path)
}

resource "aws_elastic_beanstalk_application_version" "backend_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.backend_app.name
  bucket      = aws_s3_bucket.post_board_bucket.id
  key         = aws_s3_object.backend_bundle.key
}

resource "aws_elastic_beanstalk_application" "frontend_app" {
  name        = "${var.project_name}-frontend"
  description = "Frontend application for Post Board"
}

resource "aws_s3_object" "frontend_bundle" {
  bucket = aws_s3_bucket.post_board_bucket.id
  key    = var.frontend_bundle_key
  source = var.frontend_bundle_path
  etag   = filemd5(var.frontend_bundle_path)
}

resource "aws_elastic_beanstalk_application_version" "frontend_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.frontend_app.name
  bucket      = aws_s3_bucket.post_board_bucket.id
  key         = aws_s3_object.frontend_bundle.key
}


resource "aws_elastic_beanstalk_environment" "backend_env" {
  name                = "${var.project_name}-backend-env"
  application         = aws_elastic_beanstalk_application.backend_app.name
  solution_stack_name = var.eb_solution_stack_name
  version_label       = aws_elastic_beanstalk_application_version.backend_version.name

  depends_on = [
    aws_db_instance.post_board_db,
    aws_acm_certificate_validation.cert_wait
  ]

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.app_private_a.id},${aws_subnet.app_private_b.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.edge_public_a.id},${aws_subnet.edge_public_b.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.backend_instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.backend_instance_sg.id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.backend_alb_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.eb_instance_profile
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = var.backend_health_check_path
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = var.eb_service_role
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = var.eb_process_port
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elbv2:listener:80"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = aws_acm_certificate.cert.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVER_PORT"
    value     = var.backend_container_port
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APP_NAME"
    value     = "${var.project_name}-backend"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_URL"
    value     = "jdbc:postgresql://${aws_db_instance.post_board_db.address}:${var.database_port}/${var.db_name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = aws_db_instance.post_board_db.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = aws_db_instance.post_board_db.password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_ISSUER_URI"
    value     = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.post_board_users.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MAX_FILE_SIZE"
    value     = var.max_file_size
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MAX_REQUEST_SIZE"
    value     = var.max_request_size
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PAGE_DEFAULT_SIZE"
    value     = var.page_default_size
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PAGE_MAX_SIZE"
    value     = var.page_max_size
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SWAGGER_UI_PATH"
    value     = var.swagger_ui_path
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_ENDPOINT"
    value     = var.s3_endpoint
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_REGION"
    value     = var.aws_region
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_BUCKET"
    value     = aws_s3_bucket.post_board_bucket.bucket
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_OBJECT_KEY_PREFIX"
    value     = var.s3_object_key_prefix
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_PATH_STYLE_ACCESS"
    value     = var.s3_path_style_access
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = var.cloudwatch_log_retention_days
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "true"
  }
}

resource "aws_elastic_beanstalk_environment" "frontend_env" {
  name                = "${var.project_name}-frontend-env"
  application         = aws_elastic_beanstalk_application.frontend_app.name
  solution_stack_name = var.eb_solution_stack_name
  version_label       = aws_elastic_beanstalk_application_version.frontend_version.name

  depends_on = [
    aws_acm_certificate_validation.cert_wait,
    aws_elastic_beanstalk_environment.backend_env
  ]

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.app_private_a.id},${aws_subnet.app_private_b.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.edge_public_a.id},${aws_subnet.edge_public_b.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.frontend_instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.frontend_instance_sg.id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.frontend_alb_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.eb_instance_profile
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = var.eb_service_role
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = var.frontend_health_check_path
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = var.eb_process_port
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elbv2:listener:80"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = aws_acm_certificate.cert.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = var.frontend_container_port
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "BACKEND_URL"
    value     = var.backend_public_url
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APP_API_BASE_URL"
    value     = var.frontend_api_base_url
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "POSTS_PAGE_SIZE"
    value     = var.posts_page_size
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "POSTS_POLLING_INTERVAL_MS"
    value     = var.posts_polling_interval_ms
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "POSTS_MAX_SYNC_PAGES"
    value     = var.posts_max_sync_pages
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_AUTHORITY"
    value     = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.post_board_users.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_CLIENT_ID"
    value     = aws_cognito_user_pool_client.client.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_REDIRECT_URI"
    value     = local.frontend_public_url_with_slash
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_RESPONSE_TYPE"
    value     = "code"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_SCOPE"
    value     = var.frontend_cognito_scope
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_DOMAIN"
    value     = "https://${aws_cognito_user_pool_domain.post_board_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_LOGOUT_URI"
    value     = local.frontend_public_url_with_slash
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = var.cloudwatch_log_retention_days
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "true"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_alb_target_5xx" {
  alarm_name          = "${var.project_name}-backend-alb-target-5xx"
  alarm_description   = "Backend ALB target 5xx responses are above the expected threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.backend_alb_5xx_alarm_evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.cloudwatch_alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.backend_alb_5xx_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.backend_alb_dimension
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  alarm_description   = "PostBoard RDS CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.rds_cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.cloudwatch_alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_cpu_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.post_board_db.id
  }
}


output "ssl_certificate_validation_data" {
  value = [
    for dvo in aws_acm_certificate.cert.domain_validation_options : {
      domain       = dvo.domain_name
      record_name  = dvo.resource_record_name
      record_type  = dvo.resource_record_type
      record_value = dvo.resource_record_value
    }
  ]
}

output "rds_endpoint" {
  value = aws_db_instance.post_board_db.endpoint
}

output "backend_eb_url" {
  value = aws_elastic_beanstalk_environment.backend_env.cname
}

output "frontend_eb_url" {
  value = aws_elastic_beanstalk_environment.frontend_env.cname
}

output "backend_load_balancers_raw" {
  value = aws_elastic_beanstalk_environment.backend_env.load_balancers
}