variable "slack_workspace_id" {
  description = "Slack workspace ID (format: T0XXXXXXXXX). Get from AWS Chatbot console after authorizing Slack."
  type        = string

  validation {
    condition     = can(regex("^T[A-Z0-9]{8,}$", var.slack_workspace_id))
    error_message = "Must be a valid Slack workspace ID starting with T."
  }
}

variable "slack_channel_id" {
  description = "Slack channel ID (format: C0XXXXXXXXX). All accounts will post to this same channel."
  type        = string

  validation {
    condition     = can(regex("^C[A-Z0-9]{8,}$", var.slack_channel_id))
    error_message = "Must be a valid Slack channel ID starting with C."
  }
}

variable "slack_channel_name" {
  description = "Slack channel name (for display purposes only)"
  type        = string
  default     = "amazonq-multi-account"
}

variable "configuration_name" {
  description = "Name for this AWS Chatbot configuration. Should be unique per account."
  type        = string
  default     = "AmazonQ-Chatbot"
}

variable "chatbot_role_name" {
  description = "Name for the AWS Chatbot IAM role"
  type        = string
  default     = "AmazonQ-Chatbot-Role"

  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]{1,64}$", var.chatbot_role_name))
    error_message = "Role name must match pattern ^[a-zA-Z0-9+=,.@_-]{1,64}$."
  }
}

variable "account_nickname" {
  description = "Optional nickname for this account (e.g., 'Production', 'Development'). Will be added as a tag."
  type        = string
  default     = ""
}

variable "logging_level" {
  description = "Logging level for AWS Chatbot"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["ERROR", "INFO", "NONE"], var.logging_level)
    error_message = "Logging level must be ERROR, INFO, or NONE."
  }
}

variable "create_test_sns_topic" {
  description = "Create a test SNS topic for notifications (recommended for testing)"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
