data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  common_tags = merge(
    {
      Project   = "AmazonQ-Chatbot"
      ManagedBy = "Terraform"
    },
    var.account_nickname != "" ? { AccountNickname = var.account_nickname } : {},
    var.tags
  )
}

# IAM Role for AWS Chatbot
resource "aws_iam_role" "chatbot" {
  name        = var.chatbot_role_name
  description = "IAM role for Amazon Q Developer Chatbot"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "chatbot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonQDeveloperAccess",
    "arn:aws:iam::aws:policy/AmazonQFullAccess"
  ]

  tags = merge(
    local.common_tags,
    {
      Name = var.chatbot_role_name
    }
  )
}

# SNS Topic for Notifications (Optional - for testing)
resource "aws_sns_topic" "notifications" {
  count = var.create_test_sns_topic ? 1 : 0

  name         = "${var.configuration_name}-Notifications"
  display_name = "Amazon Q Chatbot Notifications - ${var.account_nickname}"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.configuration_name}-Notifications"
    }
  )
}

# SNS Topic Subscription to Email
resource "aws_sns_topic_subscription" "notifications_email" {
  count = var.create_test_sns_topic ? 1 : 0

  protocol  = "email"
  topic_arn = aws_sns_topic.notifications[0].arn
  endpoint  = "amazonq-${local.account_id}@example.com"
}

# CloudWatch Alarm for testing SNS notifications
resource "aws_cloudwatch_metric_alarm" "test_alarm" {
  count = var.create_test_sns_topic ? 1 : 0

  alarm_name          = "${var.configuration_name}-Test-Alarm"
  alarm_description   = "Test alarm for Amazon Q Chatbot SNS notifications"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.notifications[0].arn
  ]

  tags = local.common_tags
}

# AWS Chatbot Slack Configuration
resource "aws_chatbot_slack_channel_configuration" "this" {
  configuration_name = var.configuration_name
  slack_workspace_id = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  iam_role_arn       = aws_iam_role.chatbot.arn

  guardrail_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonQDeveloperAccess",
    "arn:aws:iam::aws:policy/AmazonQFullAccess"
  ]

  sns_topic_arns = var.create_test_sns_topic ? [
    aws_sns_topic.notifications[0].arn
  ] : []

  logging_level       = var.logging_level
  user_role_required  = false

  tags = merge(
    local.common_tags,
    {
      Name         = var.configuration_name
      SlackChannel = var.slack_channel_name
      AccountId    = local.account_id
    }
  )
}

# CloudWatch Log Group for Chatbot
resource "aws_cloudwatch_log_group" "chatbot" {
  name              = "/aws/chatbot/${var.configuration_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.configuration_name}-logs"
      AccountId = local.account_id
    }
  )
}
