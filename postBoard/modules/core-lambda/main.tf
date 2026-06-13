locals {
  functions = {
    get_posts = {
      function_name = "${var.project_name}-get-posts"
      definition    = "getPosts"
    }
    get_post = {
      function_name = "${var.project_name}-get-post"
      definition    = "getPost"
    }
    create_post = {
      function_name = "${var.project_name}-create-post"
      definition    = "createPost"
    }
    get_comments = {
      function_name = "${var.project_name}-get-comments"
      definition    = "getComments"
    }
    create_comment = {
      function_name = "${var.project_name}-create-comment"
      definition    = "createComment"
    }
    set_reaction = {
      function_name = "${var.project_name}-set-reaction"
      definition    = "setReaction"
    }
  }

  common_environment = {
    APP_NAME                                   = "postboard-core-lambda"
    AWS_REGION                                 = var.aws_region
    DB_PASSWORD                                = var.db_password
    DB_URL                                     = "jdbc:postgresql://${var.rds_address}:${var.db_port}/${var.db_name}"
    DB_USERNAME                                = var.db_username
    NOTIFICATION_EVENTS_QUEUE_URL              = var.notification_events_queue_url
    SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE = "2"
    SPRING_MAIN_WEB_APPLICATION_TYPE           = "none"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.functions

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.common_tags
}

resource "aws_lambda_function" "core" {
  for_each = local.functions

  filename         = var.artifact_path
  function_name    = each.value.function_name
  handler          = "org.springframework.cloud.function.adapter.aws.FunctionInvoker::handleRequest"
  memory_size      = var.lambda_memory_size
  role             = var.lambda_role_arn
  runtime          = "java21"
  source_code_hash = filebase64sha256(var.artifact_path)
  timeout          = var.lambda_timeout_seconds

  environment {
    variables = merge(local.common_environment, {
      spring_cloud_function_definition = each.value.definition
    })
  }

  vpc_config {
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.lambda_subnet_ids
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = var.common_tags
}
