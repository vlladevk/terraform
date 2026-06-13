output "client_id" {
  value = aws_cognito_user_pool_client.app.id
}

output "issuer_uri" {
  value = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
}

output "user_pool_id" {
  value = aws_cognito_user_pool.users.id
}
