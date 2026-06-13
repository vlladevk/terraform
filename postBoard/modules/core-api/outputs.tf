output "api_base_url" {
  value = "${aws_apigatewayv2_api.core.api_endpoint}/api/v1"
}

output "api_url" {
  value = aws_apigatewayv2_api.core.api_endpoint
}
