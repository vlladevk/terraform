output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "log_group_names" {
  value = {
    for key, log_group in aws_cloudwatch_log_group.service : key => log_group.name
  }
}

output "service_names" {
  value = {
    for key, service in aws_ecs_service.service : key => service.name
  }
}
