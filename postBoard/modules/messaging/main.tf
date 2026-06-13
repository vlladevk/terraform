resource "aws_sns_topic" "auth_events" {
  name = "${var.project_name}-auth-events"

  tags = var.common_tags
}

resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-notifications"

  tags = var.common_tags
}

resource "aws_sqs_queue" "notification_events_dlq" {
  name                      = "${var.project_name}-notification-events-dlq"
  message_retention_seconds = 1209600

  tags = var.common_tags
}

resource "aws_sqs_queue" "notification_events" {
  name                       = "${var.project_name}-notification-events"
  message_retention_seconds  = 345600
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds

  # Failed messages become observable in the DLQ after bounded retries.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_events_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = var.common_tags
}

resource "aws_sqs_queue_policy" "notification_events" {
  queue_url = aws_sqs_queue.notification_events.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAuthTopicToSendMessages"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.notification_events.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.auth_events.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "auth_events_to_notification_queue" {
  endpoint  = aws_sqs_queue.notification_events.arn
  protocol  = "sqs"
  topic_arn = aws_sns_topic.auth_events.arn
}
