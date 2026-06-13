output "auth_users_table_name" {
  value = aws_dynamodb_table.auth_users.name
}

output "core_db_address" {
  value = aws_db_instance.core.address
}

output "core_db_endpoint" {
  value = aws_db_instance.core.endpoint
}

output "media_bucket_name" {
  value = aws_s3_bucket.media.bucket
}

output "media_metadata_table_name" {
  value = aws_dynamodb_table.media_metadata.name
}

output "notification_subscribers_table_name" {
  value = aws_dynamodb_table.notification_subscribers.name
}

output "notifications_table_name" {
  value = aws_dynamodb_table.notifications.name
}
