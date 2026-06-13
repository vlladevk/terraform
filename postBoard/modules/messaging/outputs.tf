output "auth_events_topic_arn" {
  value = aws_sns_topic.auth_events.arn
}

output "notification_events_dlq_name" {
  value = aws_sqs_queue.notification_events_dlq.name
}

output "notification_events_queue_arn" {
  value = aws_sqs_queue.notification_events.arn
}

output "notification_events_queue_name" {
  value = aws_sqs_queue.notification_events.name
}

output "notification_events_queue_url" {
  value = aws_sqs_queue.notification_events.url
}

output "notifications_topic_arn" {
  value = aws_sns_topic.notifications.arn
}
