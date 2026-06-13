output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "vpc_endpoint_security_group_id" {
  value = aws_security_group.vpc_endpoint.id
}
