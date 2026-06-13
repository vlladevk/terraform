output "function_arns" {
  value = {
    for key, function in aws_lambda_function.core : key => function.invoke_arn
  }
}

output "function_names" {
  value = {
    for key, function in aws_lambda_function.core : key => function.function_name
  }
}

output "log_group_names" {
  value = {
    for key, log_group in aws_cloudwatch_log_group.lambda : key => log_group.name
  }
}
