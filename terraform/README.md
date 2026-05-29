# Amazon Q Developer Chatbot - Terraform Configuration

This Terraform configuration creates the AWS infrastructure for Amazon Q Developer Chatbot that integrates with Slack. It's the Terraform equivalent of the CloudFormation template in the `cloudformation/` directory.

## Resources Created

This configuration creates the following AWS resources:

1. **IAM Role** - For AWS Chatbot with necessary permissions
2. **AWS Chatbot Slack Channel Configuration** - Connects AWS to your Slack workspace
3. **CloudWatch Log Group** - For Chatbot logs with 30-day retention
4. **SNS Topic** (optional) - For test notifications
5. **SNS Subscription** (optional) - Email subscription to the SNS topic
6. **CloudWatch Alarm** (optional) - Test alarm for SNS notifications

## Prerequisites

1. **Terraform**: Version >= 1.0
2. **AWS CLI**: Configured with appropriate credentials
3. **Slack Workspace**: You must authorize AWS Chatbot with your Slack workspace first
   - Go to AWS Chatbot console: https://console.aws.amazon.com/chatbot/
   - Click "Configure new client" and authorize Slack
   - Note down your Workspace ID and Channel ID

## Quick Start

### 1. Copy Example Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars

Update the file with your actual values:

```hcl
slack_workspace_id = "T0XXXXXXXXX"  # Your Slack workspace ID
slack_channel_id   = "C0XXXXXXXXX"  # Your Slack channel ID
slack_channel_name = "amazonq-multi-account"
configuration_name = "AmazonQ-MyAccount"
account_nickname   = "Production"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

### 6. View Outputs

After successful deployment:

```bash
terraform output
terraform output -raw deployment_instructions
```

## Configuration Options

### Required Variables

- `slack_workspace_id` - Your Slack workspace ID (starts with T)
- `slack_channel_id` - Your Slack channel ID (starts with C)

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `slack_channel_name` | `amazonq-multi-account` | Display name for Slack channel |
| `configuration_name` | `AmazonQ-Chatbot` | Name for AWS Chatbot configuration |
| `chatbot_role_name` | `AmazonQ-Chatbot-Role` | IAM role name |
| `account_nickname` | `""` | Friendly name for this account |
| `logging_level` | `INFO` | Logging level (ERROR, INFO, NONE) |
| `create_test_sns_topic` | `true` | Create test SNS topic and alarm |
| `log_retention_days` | `30` | CloudWatch log retention period |
| `tags` | `{}` | Additional resource tags |

## Multi-Account Deployment

To deploy across multiple AWS accounts:

1. **Deploy to first account:**
   ```bash
   # In account 1
   terraform apply
   ```

2. **Use Terraform Workspaces** (recommended):
   ```bash
   # Create workspace for second account
   terraform workspace new account-2
   
   # Update terraform.tfvars with account-2 specific values
   # Apply
   terraform apply
   ```

3. **Or use separate directories:**
   ```bash
   # Copy configuration
   cp -r terraform terraform-account2
   cd terraform-account2
   
   # Update terraform.tfvars
   # Apply
   terraform apply
   ```

## Variable Files for Different Accounts

You can create multiple `.tfvars` files for different accounts:

**primary-account.tfvars:**
```hcl
slack_workspace_id = "T04SR5XV56X"
slack_channel_id   = "C0B5UE340PP"
configuration_name = "AmazonQ-Primary"
account_nickname   = "Primary"
```

**dev-account.tfvars:**
```hcl
slack_workspace_id = "T04SR5XV56X"
slack_channel_id   = "C0B5UE340PP"
configuration_name = "AmazonQ-Development"
account_nickname   = "Development"
```

Then apply with:
```bash
terraform apply -var-file="primary-account.tfvars"
```

## Testing the Deployment

After deployment, test in Slack:

1. **Query AWS resources:**
   ```
   @Amazon Q list ec2 instances
   @Amazon Q show s3 buckets
   @Amazon Q describe vpc resources
   ```

2. **Test SNS notifications** (if enabled):
   ```bash
   # Publish test message
   aws sns publish \
     --topic-arn $(terraform output -raw sns_topic_arn) \
     --message "Test notification from Amazon Q Chatbot"
   ```

## Outputs

The configuration provides these outputs:

- `chatbot_role_arn` - IAM role ARN
- `chatbot_role_name` - IAM role name
- `chatbot_configuration_arn` - Chatbot configuration ARN
- `account_id` - AWS account ID
- `slack_channel_id` - Slack channel ID
- `cloudwatch_log_group` - Log group name
- `sns_topic_arn` - SNS topic ARN (if created)
- `sns_topic_name` - SNS topic name (if created)
- `test_alarm_name` - Test alarm name (if created)
- `deployment_instructions` - Usage instructions

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Comparison with CloudFormation

This Terraform configuration is functionally equivalent to the CloudFormation template in `cloudformation/amazonq-chatbot-account.yaml`. Key differences:

| Aspect | CloudFormation | Terraform |
|--------|---------------|-----------|
| State Management | Stack-based | State file (local/remote) |
| Variable Files | JSON parameter files | `.tfvars` files |
| Conditionals | `!If`, `!Equals` | `count` with boolean |
| Outputs | Stack outputs | `terraform output` |
| Multi-account | Deploy stack per account | Workspaces or directories |

## Troubleshooting

### Chatbot Not Receiving Messages

1. Verify Slack authorization in AWS Chatbot console
2. Check IAM role permissions
3. Review CloudWatch logs: `/aws/chatbot/<configuration_name>`

### SNS Topic Not Working

1. Confirm SNS topic subscription (check email)
2. Verify topic policy allows publishing
3. Check CloudWatch alarm configuration

### Permission Issues

The IAM role includes `AdministratorAccess` for full functionality. For production, consider using more restrictive policies based on your requirements.

## Security Considerations

- The default configuration uses `AdministratorAccess` - consider using least-privilege policies for production
- SNS email subscription uses a placeholder email - update for real notifications
- CloudWatch logs are retained for 30 days - adjust based on compliance requirements
- Consider enabling encryption for SNS topics in production

## Additional Resources

- [AWS Chatbot Documentation](https://docs.aws.amazon.com/chatbot/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon Q Developer Documentation](https://docs.aws.amazon.com/amazonq/)

## Support

For issues or questions:
1. Check CloudFormation equivalent in `cloudformation/` directory
2. Review AWS Chatbot console for configuration status
3. Check Terraform state: `terraform show`
