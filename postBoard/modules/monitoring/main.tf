resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.lambda_function_names

  alarm_name          = "${each.value}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.lambda_error_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = var.lambda_function_names

  alarm_name          = "${each.value}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Average"
  threshold           = var.lambda_duration_alarm_threshold_ms
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "queue_visible_messages" {
  alarm_name          = "${var.project_name}-notification-events-visible"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = var.sqs_visible_messages_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = var.queue_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project_name}-notification-events-dlq"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = var.dlq_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_log_metric_filter" "notification_errors" {
  log_group_name = var.notification_log_group_name
  name           = "${var.project_name}-notification-errors"
  pattern        = "ERROR"

  metric_transformation {
    name      = "NotificationServiceErrors"
    namespace = "Postboard"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "notification_errors" {
  alarm_name          = "${var.project_name}-notification-service-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NotificationServiceErrors"
  namespace           = "Postboard"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  tags = var.common_tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          region = var.aws_region
          title  = "Core Lambda errors"
          metrics = [
            for function_name in values(var.lambda_function_names) :
            ["AWS/Lambda", "Errors", "FunctionName", function_name, { stat = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          region = var.aws_region
          title  = "Core Lambda duration"
          metrics = [
            for function_name in values(var.lambda_function_names) :
            ["AWS/Lambda", "Duration", "FunctionName", function_name, { stat = "Average" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          region = var.aws_region
          title  = "Notification SQS"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.queue_name],
            [".", "ApproximateNumberOfMessagesNotVisible", ".", "."],
            [".", "ApproximateAgeOfOldestMessage", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          region = var.aws_region
          title  = "Notification service"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.notification_service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            ["Postboard", "NotificationServiceErrors"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          region = var.aws_region
          title  = "Notification DLQ"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.dlq_name],
            [".", "ApproximateAgeOfOldestMessage", ".", "."]
          ]
        }
      }
    ]
  })
}
