locals {
  routes = {
    "GET /api/v1/posts" = {
      function_key  = "get_posts"
      authorization = false
    }
    "GET /api/v1/posts/{id}" = {
      function_key  = "get_post"
      authorization = false
    }
    "POST /api/v1/posts" = {
      function_key  = "create_post"
      authorization = true
    }
    "GET /api/v1/posts/{id}/comments" = {
      function_key  = "get_comments"
      authorization = false
    }
    "POST /api/v1/posts/{id}/comments" = {
      function_key  = "create_comment"
      authorization = true
    }
    "POST /api/v1/posts/{id}/reactions" = {
      function_key  = "set_reaction"
      authorization = true
    }
  }
}

resource "aws_apigatewayv2_api" "core" {
  name          = "${var.project_name}-core-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["authorization", "content-type"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
    max_age       = 3600
  }

  tags = var.common_tags
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.core.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-cognito-jwt"

  jwt_configuration {
    audience = [var.client_id]
    issuer   = var.issuer_uri
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each = var.lambda_function_arns

  api_id                 = aws_apigatewayv2_api.core.id
  integration_method     = "POST"
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "core" {
  for_each = local.routes

  api_id             = aws_apigatewayv2_api.core.id
  authorization_type = each.value.authorization ? "JWT" : "NONE"
  authorizer_id      = each.value.authorization ? aws_apigatewayv2_authorizer.jwt.id : null
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.lambda[each.value.function_key].id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.core.id
  auto_deploy = true
  name        = "$default"

  tags = var.common_tags
}

resource "aws_lambda_permission" "allow_api_gateway" {
  for_each = var.lambda_function_names

  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.core.execution_arn}/*/*"
}
