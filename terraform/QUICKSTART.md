# Quick Start Guide

## Deploy in 5 Minutes

### Option 1: Using Existing Parameter File

If you have your account parameters ready (like `primary-account.tfvars` or `my-account.tfvars`):

```bash
cd terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan -var-file="primary-account.tfvars"

# Deploy
terraform apply -var-file="primary-account.tfvars"
```

### Option 2: Using terraform.tfvars

```bash
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or vim, code, etc.

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Option 3: Interactive (Command Line)

```bash
cd terraform
terraform init

terraform apply \
  -var="slack_workspace_id=T04SR5XV56X" \
  -var="slack_channel_id=C0B5UE340PP" \
  -var="configuration_name=AmazonQ-MyAccount" \
  -var="account_nickname=Production"
```

## What Gets Created?

- ✅ IAM Role for AWS Chatbot
- ✅ Slack Channel Configuration
- ✅ CloudWatch Log Group
- ✅ SNS Topic (optional, for testing)
- ✅ Test CloudWatch Alarm (optional)

## After Deployment

View the deployment instructions:

```bash
terraform output -raw deployment_instructions
```

Test in Slack:

```
@Amazon Q help
@Amazon Q list ec2 instances
@Amazon Q show s3 buckets
```

## Multi-Account Setup

### Deploy to Multiple Accounts

**Using Terraform Workspaces:**

```bash
# Account 1 (default workspace)
terraform apply -var-file="primary-account.tfvars"

# Account 2
terraform workspace new account-2
terraform apply -var-file="my-account.tfvars"

# Account 3
terraform workspace new account-3
terraform apply -var-file="dev-account.tfvars"

# Switch between accounts
terraform workspace select account-2
terraform output
```

**Using AWS Profile:**

```bash
# Deploy to account 1
AWS_PROFILE=account1 terraform apply -var-file="primary-account.tfvars"

# Deploy to account 2
AWS_PROFILE=account2 terraform apply -var-file="my-account.tfvars"
```

## Common Commands

```bash
# View current state
terraform show

# List all outputs
terraform output

# Get specific output
terraform output chatbot_role_arn

# Update configuration
terraform apply

# Destroy everything
terraform destroy
```

## Troubleshooting

### "Error: Invalid provider configuration"

Make sure you have AWS credentials configured:

```bash
aws configure
# or
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### "Error: Reference to undeclared resource"

Run `terraform init` first to download providers.

### "Slack workspace not authorized"

1. Go to AWS Chatbot console
2. Click "Configure new client"
3. Authorize your Slack workspace
4. Get Workspace ID and Channel ID

## Next Steps

- Review the [full README](README.md) for detailed documentation
- Check the [CloudFormation comparison](../cloudformation/) for reference
- Customize IAM permissions for production use
- Set up remote state backend for team collaboration

## Quick Reference

| File | Purpose |
|------|---------|
| `main.tf` | Main resource definitions |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output definitions |
| `versions.tf` | Provider requirements |
| `terraform.tfvars` | Your variable values (create this) |
| `*.tfvars` | Pre-configured variable files |
| `.gitignore` | Exclude sensitive files from git |

## Migration from CloudFormation

If you're migrating from the CloudFormation stack:

1. **Export CloudFormation parameters:**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name your-stack-name \
     --query 'Stacks[0].Parameters'
   ```

2. **Create matching tfvars file** using the exported values

3. **Import existing resources** (optional):
   ```bash
   # Import IAM role
   terraform import aws_iam_role.chatbot AmazonQ-Chatbot-Role
   
   # Import Chatbot configuration
   terraform import aws_chatbot_slack_channel_configuration.this arn:aws:chatbot::ACCOUNT:chat-configuration/slack-channel/CONFIG_NAME
   ```

4. **Review plan carefully** before applying:
   ```bash
   terraform plan
   ```

5. **Consider running both** (CloudFormation and Terraform) in parallel initially for testing
