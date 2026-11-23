locals {
  artifact_hash = filesha256(var.artifact_path)
  artifact_key  = "lambda/${local.artifact_hash}/${basename(var.artifact_path)}"

  functions = {
    get_posts = {
      definition      = "getPosts"
      function_name   = "${var.project_name}-get-posts"
      memory_size     = 1024
      timeout_seconds = 20
    }
    get_post = {
      definition      = "getPost"
      function_name   = "${var.project_name}-get-post"
      memory_size     = 1024
      timeout_seconds = 20
    }
    create_post = {
      definition      = "createPost"
      function_name   = "${var.project_name}-create-post"
      memory_size     = 1536
      timeout_seconds = 30
    }
    get_comments = {
      definition      = "getComments"
      function_name   = "${var.project_name}-get-comments"
      memory_size     = 1024
      timeout_seconds = 20
    }
    create_comment = {
      definition      = "createComment"
      function_name   = "${var.project_name}-create-comment"
      memory_size     = 1536
      timeout_seconds = 30
    }
    set_reaction = {
      definition      = "setReaction"
      function_name   = "${var.project_name}-set-reaction"
      memory_size     = 1536
      timeout_seconds = 30
    }
  }

  common_environment = {
    APP_NAME                                   = "postboard-core-lambda"
    DB_PASSWORD                                = var.db_password
    DB_URL                                     = "jdbc:postgresql://${var.rds_address}:${var.db_port}/${var.db_name}"
    DB_USERNAME                                = var.db_username
    MAIN_CLASS                                 = "com.vlladevk.postboardcoreservice.PostboardCoreServiceApplication"
    NOTIFICATION_EVENTS_QUEUE_URL              = var.notification_events_queue_url
    SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE = "2"
    SPRING_MAIN_WEB_APPLICATION_TYPE           = "none"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket        = "${var.project_name}-lambda-artifacts-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-lambda-artifacts"
  })
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.lambda_artifacts.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "lambda_artifact" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  key    = local.artifact_key
  source = var.artifact_path
  etag   = filemd5(var.artifact_path)

  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.functions

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.common_tags
}

resource "aws_lambda_function" "core" {
  for_each = local.functions

  function_name    = each.value.function_name
  handler          = "org.springframework.cloud.function.adapter.aws.FunctionInvoker::handleRequest"
  memory_size      = each.value.memory_size
  role             = var.lambda_role_arn
  runtime          = "java21"
  s3_bucket        = aws_s3_bucket.lambda_artifacts.id
  s3_key           = aws_s3_object.lambda_artifact.key
  source_code_hash = filebase64sha256(var.artifact_path)
  timeout          = each.value.timeout_seconds

  environment {
    variables = merge(local.common_environment, {
      spring_cloud_function_definition = each.value.definition
    })
  }

  vpc_config {
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.lambda_subnet_ids
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_s3_object.lambda_artifact
  ]

  tags = var.common_tags
}
