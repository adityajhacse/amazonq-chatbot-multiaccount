# Amazon Q Developer Chatbot - Multi-Account Slack Integration

Deploy Amazon Q Developer to Slack with support for multiple AWS accounts. Each account posts to the same Slack channel, allowing you to query resources across all your accounts simultaneously.

## Architecture

```
┌─────────────────────────────────────────────────┐
│         Slack Channel: #amazonq-multi-account   │
└───────────────┬─────────────────────────────────┘
                │
                │ All accounts connect to same channel
                │
    ┌───────────┼───────────┬─────────────┐
    │           │           │             │
    ▼           ▼           ▼             ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│Account 1│ │Account 2│ │Account 3│ │Account N│
│         │ │         │ │         │ │         │
│Chatbot  │ │Chatbot  │ │Chatbot  │ │Chatbot  │
│Config   │ │Config   │ │Config   │ │Config   │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
```

**How it works:**
- Deploy the same CloudFormation template to each AWS account
- All accounts connect to the same Slack channel
- When you ask a question, all accounts respond simultaneously
- Each response clearly identifies which account it came from

## Features

✅ **Simple Setup** - Single CloudFormation template for all accounts  
✅ **Multi-Account** - Query resources across all AWS accounts from one Slack channel  
✅ **Read-Only by Default** - AdministratorAccess role with ReadOnlyAccess guardrail policy  
✅ **Clear Responses** - Each account identifies itself in responses  
✅ **Easy to Maintain** - Independent account configurations  
✅ **Cost-Effective** - ~$0.50 per account per month (CloudWatch Logs only)  

## Prerequisites

### 1. Slack Workspace Authorization (Required Per AWS Account)

**⚠️ Important:** This step **cannot be automated** and must be done **manually in EACH AWS account** before deploying the CloudFormation stack to that account.

**Steps (Repeat for Each AWS Account):**

1. **Log in to the AWS Console** for the specific account you're deploying to
2. Navigate to **AWS Chatbot** service
3. Click **"Configure a chat client"**
4. Select **"Slack"**
5. Click **"Configure client"**
6. You'll be redirected to Slack to authorize
7. Click **"Allow"** to authorize AWS Chatbot for your workspace
8. After authorization, you'll see your **Workspace ID** (format: `T0XXXXXXXXX`)
9. **Save this Workspace ID** - use the same ID for all accounts

**Key Points:**
- ⚠️ Must be done **once per AWS account** (not just once total)
- ✅ The **Workspace ID remains the same** across all accounts (e.g., T04SR5XV56X)
- ✅ Each account gets its own OAuth authorization token
- ✅ Requires Slack workspace admin permissions
- ❌ Cannot be automated (requires interactive OAuth)

**Why Per-Account?**
- The **Workspace ID** (T04SR5XV56X) identifies your Slack workspace (stays the same)
- The **OAuth authorization** gives a specific AWS account permission to access that workspace (unique per account)
- Think of it like: Workspace ID = your house address (same), Authorization = individual keys (different per person)

### 2. Create Slack Channel

1. In Slack, create a channel (e.g., `#amazonq-multi-account`)
2. Make it **public** (or you'll need to invite the bot later)
3. Right-click the channel → **"View channel details"**
4. Scroll to the bottom and copy the **Channel ID** (format: `C0XXXXXXXXX`)
5. **Save this Channel ID** - you'll use it for all accounts

### 3. AWS Setup

- AWS CLI installed and configured
- Access to each AWS account you want to configure
- Permissions to create IAM roles and Chatbot configurations

## Quick Start

### Step 0: Slack Authorization (Required for Each Account) ⚠️

**Before deploying to each AWS account**, you must authorize your Slack workspace in that specific account.

📖 **See [SLACK_SETUP_GUIDE.md](./SLACK_SETUP_GUIDE.md)** for detailed step-by-step instructions.

**Summary (Repeat for Each Account):**
1. **Log into the specific AWS account** you're deploying to
2. Go to AWS Chatbot console → Configure Slack
3. Click "Allow" in Slack to authorize
4. Get your **Workspace ID** (e.g., `T04SR5XV56X`) - same for all accounts
5. Get your **Channel ID** from Slack (e.g., `C0B5UE340PP`) - same for all accounts

**Important:**
- ⚠️ Authorization must be done **in each AWS account separately**
- ✅ Use the **same Workspace ID and Channel ID** for all accounts
- ⚠️ If you skip this step, CloudFormation deployment will fail with "workspace not authorized"

⚠️ **This cannot be automated** - it's a manual OAuth process per account (takes ~2 minutes per account).

### Step 1: Prepare Parameter File

Create a parameter file for each account (or use the same file with different values):

```bash
cd ~/Desktop/amazonq-chatbot-aditya/cloudformation/parameters
cp amazonq-chatbot-account.json.example my-account.json
```

Edit `my-account.json`:
```json
[
  {
    "ParameterKey": "SlackWorkspaceId",
    "ParameterValue": "T04SR5XV56X"
  },
  {
    "ParameterKey": "SlackChannelId",
    "ParameterValue": "C0B5UE340PP"
  },
  {
    "ParameterKey": "ConfigurationName",
    "ParameterValue": "AmazonQ-Production-Account"
  },
  {
    "ParameterKey": "AccountNickname",
    "ParameterValue": "Production"
  }
]
```

**Important:** 
- Use the **same** `SlackWorkspaceId` and `SlackChannelId` for all accounts
- Use a **unique** `ConfigurationName` for each account

### Step 2: Deploy to Each Account

Deploy to **each** AWS account separately. **Remember:** You must authorize Slack in each account BEFORE deploying the stack.

```bash
# Switch to the target account
export AWS_PROFILE=account-profile-name

cd ~/Desktop/amazonq-chatbot-aditya/cloudformation

# IMPORTANT: Before running this, ensure you've authorized Slack workspace
# in this account via AWS Chatbot console (see Step 0)

# Deploy the stack
aws cloudformation create-stack \
  --stack-name amazonq-chatbot \
  --template-body file://amazonq-chatbot-account.yaml \
  --parameters file://parameters/my-account.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name amazonq-chatbot \
  --region us-east-1
```

**Repeat for each AWS account:**
1. ✅ First: Authorize Slack workspace in the account (AWS Chatbot console)
2. ✅ Then: Deploy the CloudFormation stack
3. ✅ Verify: Check stack completes successfully

### Step 3: Test in Slack

Open your Slack channel and try:

```
@Amazon Q help
@Amazon Q list ec2 instances
@Amazon Q show s3 buckets
```

You'll see responses from **all configured accounts** simultaneously!

### Step 4: Set Default Account (Optional)

When you have multiple accounts, Amazon Q will query all accounts by default. To target a specific account:

**Option 1: Use the dropdown menu (recommended)**
```
@Amazon Q set default-account
```
Amazon Q will show a dropdown menu with all available accounts. Select the one you want to use.

**Option 2: Set directly if you know the account ID**
```
@Amazon Q set default-account <account-id>
```

For example:
```
@Amazon Q set default-account 916657620953
```

After setting a default account, Amazon Q will only query that account until you change it back or reset it.

## Example Response

```
You: @Amazon Q list ec2 instances

Amazon Q responds:

[Primary - 916657620953]
Found 5 EC2 instances:
- i-123456 (web-server) - running
- i-234567 (app-server) - running

[Development - 427827265613]
Found 3 EC2 instances:
- i-345678 (test-server) - running

[Production - 888054366042]
Found 10 EC2 instances:
- i-456789 (prod-web-1) - running
- i-567890 (prod-web-2) - running
```

## Configuration Parameters

| Parameter | Description | Example | Required |
|-----------|-------------|---------|----------|
| `SlackWorkspaceId` | Your Slack workspace ID | `T04SR5XV56X` | Yes |
| `SlackChannelId` | Your Slack channel ID | `C0B5UE340PP` | Yes |
| `SlackChannelName` | Channel name (display only) | `amazonq-multi-account` | No |
| `ConfigurationName` | Unique name per account | `AmazonQ-Production` | No |
| `ChatbotRoleName` | IAM role name | `AmazonQ-Chatbot-Role` | No |
| `AccountNickname` | Display name for account | `Production` | No |
| `LoggingLevel` | Log level (ERROR/INFO/NONE) | `INFO` | No |

**Key Points:**
- `SlackWorkspaceId` and `SlackChannelId` must be **identical** across all accounts
- `ConfigurationName` must be **unique** for each account
- `AccountNickname` helps identify accounts in responses

## File Structure

```
amazonq-chatbot-aditya/
├── README.md                                      # Main documentation
├── SLACK_SETUP_GUIDE.md                          # Slack authorization guide (one-time)
├── PROJECT_STRUCTURE.txt                         # Quick reference
├── cloudformation/
│   ├── amazonq-chatbot-account.yaml              # CloudFormation template (use for ALL accounts)
│   └── parameters/
│       ├── amazonq-chatbot-account.json.example  # Example parameters
│       └── amazonq-chatbot-account-primary.json  # Sample parameters
└── scripts/
    └── deploy-multi-account.sh                    # Deployment helper script
```

## Deployment Examples

### Deploy to Multiple Accounts

**IMPORTANT:** For each account below, you must first authorize the Slack workspace in that account's AWS Chatbot console before running the CloudFormation command.

```bash
cd ~/Desktop/amazonq-chatbot-aditya/cloudformation

# Account 1 - Primary (916657620953)
# Step 1: Log into account 916657620953 console → AWS Chatbot → Authorize Slack
# Step 2: Run deployment command
export AWS_PROFILE=primary-account
aws cloudformation create-stack \
  --stack-name amazonq-chatbot \
  --template-body file://amazonq-chatbot-account.yaml \
  --parameters file://parameters/amazonq-chatbot-account-primary.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Account 2 - Development (427827265613)
# Step 1: Log into account 427827265613 console → AWS Chatbot → Authorize Slack
# Step 2: Run deployment command
export AWS_PROFILE=dev-account
aws cloudformation create-stack \
  --stack-name amazonq-chatbot \
  --template-body file://amazonq-chatbot-account.yaml \
  --parameters ParameterKey=SlackWorkspaceId,ParameterValue=T04SR5XV56X \
               ParameterKey=SlackChannelId,ParameterValue=C0B5UE340PP \
               ParameterKey=ConfigurationName,ParameterValue=AmazonQ-Dev \
               ParameterKey=AccountNickname,ParameterValue=Development \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Account 3 - Production (888054366042)
# Step 1: Log into account 888054366042 console → AWS Chatbot → Authorize Slack
# Step 2: Run deployment command
export AWS_PROFILE=prod-account
aws cloudformation create-stack \
  --stack-name amazonq-chatbot \
  --template-body file://amazonq-chatbot-account.yaml \
  --parameters ParameterKey=SlackWorkspaceId,ParameterValue=T04SR5XV56X \
               ParameterKey=SlackChannelId,ParameterValue=C0B5UE340PP \
               ParameterKey=ConfigurationName,ParameterValue=AmazonQ-Prod \
               ParameterKey=AccountNickname,ParameterValue=Production \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Deployment Checklist Per Account:**
- [ ] Log into AWS account console
- [ ] Go to AWS Chatbot service
- [ ] Configure Slack client and authorize workspace
- [ ] Verify Workspace ID matches (T04SR5XV56X)
- [ ] Run CloudFormation deployment command
- [ ] Wait for stack to complete successfully
- [ ] Test in Slack channel

## Common Slack Queries

### Account Management

```
# Set default account (use dropdown menu)
@Amazon Q set default-account

# Set default account directly
@Amazon Q set default-account 916657620953

# Reset to query all accounts
@Amazon Q reset default-account
```

### Resource Queries

```
# EC2 Instances
@Amazon Q list ec2 instances
@Amazon Q describe instance i-1234567890abcdef0
@Amazon Q show stopped ec2 instances

# S3 Buckets
@Amazon Q list s3 buckets
@Amazon Q show s3 bucket my-bucket

# Lambda Functions
@Amazon Q list lambda functions
@Amazon Q describe lambda function my-function

# VPC Resources
@Amazon Q describe vpcs
@Amazon Q list subnets

# RDS Databases
@Amazon Q list rds instances
@Amazon Q describe rds database mydb

# CloudWatch
@Amazon Q show cloudwatch alarms
@Amazon Q list cloudwatch metrics
```

## Customization

### Change Account Nickname

Update the parameter file and run:

```bash
aws cloudformation update-stack \
  --stack-name amazonq-chatbot \
  --template-body file://amazonq-chatbot-account.yaml \
  --parameters file://parameters/my-account.json \
  --capabilities CAPABILITY_NAMED_IAM
```

### Add a New Account

1. Create a parameter file (copy from example)
2. Update the values (same Slack IDs, unique ConfigurationName)
3. Deploy to the new account using the same template

## Troubleshooting

### Issue: Stack CREATE_FAILED - "Slack workspace not authorized"

**Error Message:**
```
Unable to create the configuration because Slack workspace T04SR5XV56X 
is not authorized with AWS account XXXXXXXXXXXX
```

**Solution:**
This is the most common error. The Slack workspace must be authorized **in each AWS account separately**.

1. Log into the **specific AWS account** that failed
2. Go to **AWS Chatbot** console
3. Click **"Configure a chat client"** → **"Slack"**
4. Click **"Configure client"** and authorize in Slack
5. Verify you see Workspace ID **T04SR5XV56X**
6. **Delete the failed stack:** `aws cloudformation delete-stack --stack-name amazonq-chatbot`
7. **Re-deploy** the CloudFormation stack

**Why this happens:** Each AWS account needs its own OAuth token to access the Slack workspace, even though the Workspace ID is the same.

### Issue: Amazon Q not responding in Slack

**Solutions:**
1. Verify Slack workspace is authorized in AWS Chatbot console for each account
2. For private channels, invite the bot: `/invite @Amazon Q`
3. Check CloudWatch Logs: `aws logs tail /aws/chatbot/AmazonQ-YourConfig --follow`
4. Verify stack deployed successfully: `aws cloudformation describe-stacks --stack-name amazonq-chatbot`

### Issue: Only one account responding

**Solutions:**
1. Verify all accounts have the stack deployed successfully
2. Confirm all accounts use the **same** SlackWorkspaceId and SlackChannelId
3. **Most likely:** Other accounts haven't authorized the Slack workspace - check AWS Chatbot console in each account
4. Check stack status: `aws cloudformation describe-stacks --stack-name amazonq-chatbot`

### Issue: Stack creation failed

**Solutions:**
1. Ensure `CAPABILITY_NAMED_IAM` is included in the create-stack command
2. **Verify Slack workspace is authorized in THAT SPECIFIC AWS account** (do this manually in AWS console first)
3. Check stack events: `aws cloudformation describe-stack-events --stack-name amazonq-chatbot`
4. Review error messages in CloudFormation console

## Verification Commands

```bash
# Check if stack exists
aws cloudformation describe-stacks --stack-name amazonq-chatbot

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name amazonq-chatbot \
  --query 'Stacks[0].Outputs' --output table

# Verify IAM role
aws iam get-role --role-name AmazonQ-Chatbot-Role

# List Chatbot configurations
aws chatbot describe-slack-channel-configurations

# View CloudWatch logs
aws logs tail /aws/chatbot/AmazonQ-Primary-Account --follow
```

## Update Stack

To update an existing deployment:

```bash
aws cloudformation update-stack \
  --stack-name amazonq-chatbot \
  --template-body file://amazonq-chatbot-account.yaml \
  --parameters file://parameters/my-account.json \
  --capabilities CAPABILITY_NAMED_IAM
```

## Cleanup

Remove Amazon Q from an account:

```bash
aws cloudformation delete-stack --stack-name amazonq-chatbot
aws cloudformation wait stack-delete-complete --stack-name amazonq-chatbot
```

## Cost Breakdown

**Per Account:**
- AWS Chatbot: **FREE**
- IAM Role & Policies: **FREE**
- CloudWatch Logs: **~$0.50/month** (typical usage)

**Example:**
- 3 accounts: ~$1.50/month
- 10 accounts: ~$5.00/month

## Security

### IAM Permissions Model

The template uses a **Channel Role + Guardrail Policy** approach:

**Channel Role Policies:**
- `AdministratorAccess` - Full AWS administrative permissions
- `AmazonQDeveloperAccess` - Amazon Q Developer specific permissions
- `AmazonQFullAccess` - Complete Amazon Q feature access

**Guardrail Policy:** `ReadOnlyAccess` (AWS Managed)
- Applied at the Chatbot channel level
- **Restricts actual actions** to read-only operations
- Acts as a safety boundary on top of the role

**How it works:**
1. IAM Role has full admin + Amazon Q permissions
2. Guardrail policy filters this down to `ReadOnlyAccess`
3. Amazon Q can only perform read operations despite having admin role
4. This follows AWS Chatbot's security model

### Why This Design?

✅ **Flexible:** Easy to expand permissions by changing guardrail  
✅ **Safe:** Default is read-only despite admin role  
✅ **Standard:** Follows AWS Chatbot best practices  
✅ **Auditable:** All actions logged to CloudWatch  

### Changing Permissions

To allow write operations:
1. Remove or change the `GuardrailPolicies` in the CloudFormation template
2. Or add more specific guardrail policies for your use case

### IAM Best Practices

✅ Service-specific trust policy (chatbot.amazonaws.com)  
✅ Account-scoped condition in trust policy  
✅ Guardrail policy restricts to read-only by default  
✅ CloudWatch Logs for audit trail  
✅ Independent per-account security boundaries  

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review CloudWatch Logs for errors
3. Verify Slack workspace authorization in AWS Chatbot console

## Additional Resources

- [AWS Chatbot Documentation](https://docs.aws.amazon.com/chatbot/)
- [Amazon Q Developer Documentation](https://docs.aws.amazon.com/amazonq/)
- [CloudFormation IAM Resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-iam-role.html)

---

**Version:** 2.0  
**Last Updated:** 2026-05-25  
**Author:** Aditya Jha

**Get Started:** Follow the Quick Start guide above to deploy to your first account!
