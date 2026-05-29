output "chatbot_role_arn" {
  description = "ARN of the Chatbot IAM role"
  value       = aws_iam_role.chatbot.arn
}

output "chatbot_role_name" {
  description = "Name of the Chatbot IAM role"
  value       = aws_iam_role.chatbot.name
}

output "chatbot_configuration_arn" {
  description = "ARN of the AWS Chatbot configuration"
  value       = aws_chatbot_slack_channel_configuration.this.slack_channel_id
}

output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}

output "slack_channel_id" {
  description = "Slack channel ID"
  value       = var.slack_channel_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for Chatbot logs"
  value       = aws_cloudwatch_log_group.chatbot.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = var.create_test_sns_topic ? aws_sns_topic.notifications[0].arn : null
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = var.create_test_sns_topic ? aws_sns_topic.notifications[0].name : null
}

output "test_alarm_name" {
  description = "Name of the test CloudWatch alarm"
  value       = var.create_test_sns_topic ? aws_cloudwatch_metric_alarm.test_alarm[0].alarm_name : null
}

output "deployment_instructions" {
  description = "How to use this deployment"
  value = var.create_test_sns_topic ? <<-EOT
    ✅ AWS Chatbot configured for account ${local.account_id}

    Slack Channel: ${var.slack_channel_name}
    SNS Topic: ${aws_sns_topic.notifications[0].name}
    Test Alarm: ${aws_cloudwatch_metric_alarm.test_alarm[0].alarm_name}

    To query this account in Slack:
    1. Type: @Amazon Q help
    2. Ask questions like:
       - @Amazon Q list ec2 instances
       - @Amazon Q show s3 buckets
       - @Amazon Q describe cloudwatch alarms

    To test SNS notifications:
    1. Publish to SNS topic: ${aws_sns_topic.notifications[0].name}
    2. Trigger test alarm: ${aws_cloudwatch_metric_alarm.test_alarm[0].alarm_name}
    3. Messages will appear in Slack channel

    All messages from this account will appear in the same Slack channel.
    Deploy this same template to other accounts to query multiple accounts from one channel.
  EOT : <<-EOT
    ✅ AWS Chatbot configured for account ${local.account_id}

    Slack Channel: ${var.slack_channel_name}

    To query this account in Slack:
    1. Type: @Amazon Q help
    2. Ask questions like:
       - @Amazon Q list ec2 instances
       - @Amazon Q show s3 buckets
       - @Amazon Q describe vpc resources

    All messages from this account will appear in the same Slack channel.
    Deploy this same template to other accounts to query multiple accounts from one channel.
  EOT
}
