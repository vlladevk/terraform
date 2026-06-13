output "alb_dns_name" {
  value = aws_lb.public.dns_name
}

output "alb_url" {
  value = "http://${aws_lb.public.dns_name}"
}

output "target_group_arns" {
  value = {
    for key, target_group in aws_lb_target_group.service : key => target_group.arn
  }
}
