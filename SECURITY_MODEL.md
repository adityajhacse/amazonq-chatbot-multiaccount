# Security Model - Channel Role vs Guardrail Policy

## Overview

This project uses AWS Chatbot's **recommended security model** with two layers of permissions:

1. **Channel Role** - IAM Role with multiple managed policies
   - `AdministratorAccess` - Full AWS permissions
   - `AmazonQDeveloperAccess` - Amazon Q Developer features
   - `AmazonQFullAccess` - Complete Amazon Q capabilities

2. **Guardrail Policy** - AWS Managed `ReadOnlyAccess` policy

## Architecture

```
User in Slack: @Amazon Q list ec2 instances
         ↓
AWS Chatbot receives request
         ↓
    ┌────────────────────────────────┐
    │  IAM Role Check                │
    │  Role: AmazonQ-Chatbot-Role    │
    │  Policies:                     │
    │    - AdministratorAccess       │ ← Allows everything
    │    - AmazonQDeveloperAccess    │ ← Amazon Q Developer
    │    - AmazonQFullAccess         │ ← Amazon Q features
    └────────────┬───────────────────┘
                 ↓
    ┌────────────────────────────────┐
    │  Guardrail Policy Check        │
    │  Policy: ReadOnlyAccess        │ ← Filters to read-only
    └────────────┬───────────────────┘
                 ↓
       Only Read actions allowed ✅
         (List, Describe, Get)
         ↓
    AWS API calls execute
         ↓
    Response back to Slack
```

## Why This Design?

### Traditional Approach (Not Used)
```
IAM Role → Specific read-only policy → AWS APIs
```
**Problems:**
- Hard to maintain long policy documents
- Need to update policy for every new AWS service
- Easy to miss permissions
- Inflexible

### AWS Chatbot Approach (Used)
```
IAM Role (Admin + Amazon Q) → Guardrail Policy (ReadOnly) → AWS APIs
```
**Benefits:**
- ✅ Simple role configuration (AWS managed policies)
- ✅ Full Amazon Q Developer features enabled
- ✅ Guardrail policy is AWS-managed (stays up-to-date)
- ✅ Easy to expand permissions (change guardrail)
- ✅ Follows AWS best practices
- ✅ Flexible for future needs

## How It Works

### 1. IAM Role Creation

```yaml
ChatbotRole:
  Type: AWS::IAM::Role
  Properties:
    ManagedPolicyArns:
      - 'arn:aws:iam::aws:policy/AdministratorAccess'
      - 'arn:aws:iam::aws:policy/AmazonQDeveloperAccess'
      - 'arn:aws:iam::aws:policy/AmazonQFullAccess'
```

**What this means:**
- Role can theoretically do anything in AWS
- Has full access to Amazon Q Developer features
- Has complete Amazon Q capabilities
- But it's controlled by the guardrail (next step)

### 2. Guardrail Policy Applied

```yaml
SlackChannelConfiguration:
  Type: AWS::Chatbot::SlackChannelConfiguration
  Properties:
    IamRoleArn: !GetAtt ChatbotRole.Arn
    GuardrailPolicies:
      - 'arn:aws:iam::aws:policy/ReadOnlyAccess'
```

**What this means:**
- Even though role has admin access
- AWS Chatbot enforces ReadOnlyAccess
- Only read operations are actually allowed
- Guardrail acts as a filter/boundary

## Permission Flow Example

### Example 1: List EC2 Instances (Allowed)

```
User: @Amazon Q list ec2 instances

1. IAM Role Check:
   - AdministratorAccess → ec2:DescribeInstances ✅

2. Guardrail Check:
   - ReadOnlyAccess → ec2:Describe* ✅

3. Result: ✅ Allowed, request succeeds
```

### Example 2: Stop EC2 Instance (Blocked)

```
User: @Amazon Q stop instance i-12345

1. IAM Role Check:
   - AdministratorAccess → ec2:StopInstances ✅

2. Guardrail Check:
   - ReadOnlyAccess → ec2:StopInstances ❌

3. Result: ❌ Denied by guardrail policy
```

### Example 3: Delete S3 Bucket (Blocked)

```
User: @Amazon Q delete bucket my-bucket

1. IAM Role Check:
   - AdministratorAccess → s3:DeleteBucket ✅

2. Guardrail Check:
   - ReadOnlyAccess → s3:DeleteBucket ❌

3. Result: ❌ Denied by guardrail policy
```

## What Actions Are Allowed?

With `ReadOnlyAccess` guardrail, Amazon Q can:

✅ **List Resources:**
- `ec2:Describe*`, `s3:List*`, `rds:Describe*`
- `lambda:List*`, `dynamodb:Describe*`

✅ **Get Information:**
- `ec2:Get*`, `s3:Get*` (object content)
- `iam:Get*`, `cloudformation:Describe*`

✅ **Read Logs:**
- `logs:Describe*`, `logs:FilterLogEvents`
- `cloudwatch:Get*`, `cloudwatch:List*`

❌ **Write Operations (Blocked):**
- `ec2:StartInstances`, `ec2:StopInstances`
- `s3:PutObject`, `s3:DeleteObject`
- `lambda:UpdateFunctionCode`
- `iam:CreateRole`, `iam:DeleteRole`

## Changing Permission Levels

### Option 1: Keep Read-Only (Default)

No changes needed. Current configuration:
```yaml
GuardrailPolicies:
  - 'arn:aws:iam::aws:policy/ReadOnlyAccess'
```

### Option 2: Allow Specific Write Operations

Create a custom guardrail policy:

```yaml
GuardrailPolicies:
  - 'arn:aws:iam::aws:policy/ReadOnlyAccess'
  - !Ref CustomWritePolicy

CustomWritePolicy:
  Type: AWS::IAM::ManagedPolicy
  Properties:
    PolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Action:
            - 'ec2:StartInstances'
            - 'ec2:StopInstances'
            - 'ec2:RebootInstances'
          Resource: '*'
```

### Option 3: Full Admin Access (Not Recommended)

Remove guardrail policies:
```yaml
SlackChannelConfiguration:
  Properties:
    IamRoleArn: !GetAtt ChatbotRole.Arn
    # GuardrailPolicies: []  # No guardrails
```

⚠️ **Warning:** This allows Amazon Q to perform ANY action in your AWS account!

## Security Benefits

### Defense in Depth

```
Layer 1: Slack Channel Permissions
  ↓ (Who can use the channel?)
Layer 2: AWS Chatbot Trust Policy
  ↓ (Can only be assumed by chatbot.amazonaws.com)
Layer 3: Guardrail Policy (ReadOnlyAccess)
  ↓ (Filters allowed actions)
Layer 4: IAM Role (AdministratorAccess)
  ↓ (Underlying permissions)
Layer 5: AWS Service Permissions
  ↓ (Final authorization)
Actions Execute
```

### Audit Trail

All actions are logged:
```
CloudWatch Logs:
  /aws/chatbot/AmazonQ-Primary-Account

CloudTrail:
  - Event: ec2:DescribeInstances
  - User: assumed-role/AmazonQ-Chatbot-Role/AmazonQ-session
  - Result: Success
```

### Account Isolation

Each AWS account has:
- ❌ Cannot access other accounts' resources
- ❌ Cannot assume roles in other accounts
- ✅ Independent permission boundaries
- ✅ Separate audit logs

## Comparison with Other Approaches

### Approach 1: Custom Read-Only Policy (Old)

```yaml
ManagedPolicyArns:
  - !Ref CustomReadOnlyPolicy

CustomReadOnlyPolicy:
  PolicyDocument:
    Statement:
      - Effect: Allow
        Action:
          - 'ec2:Describe*'
          - 's3:List*'
          - 'rds:Describe*'
          # ... 100+ more lines
```

**Problems:**
- 😓 Long, hard-to-maintain policy
- 😓 Needs updates for new AWS services
- 😓 Easy to miss permissions
- 😓 Hard to extend

### Approach 2: Admin Role + Guardrail (Current)

```yaml
ManagedPolicyArns:
  - 'arn:aws:iam::aws:policy/AdministratorAccess'

GuardrailPolicies:
  - 'arn:aws:iam::aws:policy/ReadOnlyAccess'
```

**Benefits:**
- 😊 Simple configuration
- 😊 AWS-managed policies (auto-updated)
- 😊 Easy to extend (change guardrail)
- 😊 Industry best practice

## Real-World Example

### User Query in Slack

```
@Amazon Q show me all running EC2 instances with their security groups
```

### What Happens Behind the Scenes

1. **Slack** sends request to AWS Chatbot
2. **AWS Chatbot** assumes `AmazonQ-Chatbot-Role`
3. **Guardrail Check:**
   - `ec2:DescribeInstances` → ✅ Allowed (read operation)
   - `ec2:DescribeSecurityGroups` → ✅ Allowed (read operation)
4. **API Calls Execute:**
   ```python
   ec2.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])
   ec2.describe_security_groups(GroupIds=[...])
   ```
5. **Response formatted and sent to Slack**

### If User Tries to Stop Instance

```
@Amazon Q stop instance i-1234567890abcdef0
```

**What Happens:**
1. **Slack** sends request to AWS Chatbot
2. **AWS Chatbot** assumes `AmazonQ-Chatbot-Role`
3. **Guardrail Check:**
   - `ec2:StopInstances` → ❌ **DENIED** (write operation)
4. **Response to Slack:** "Access Denied - Operation not permitted"

## Best Practices

### ✅ Do

- Keep ReadOnlyAccess guardrail by default
- Review CloudWatch Logs regularly
- Use specific guardrails for write operations if needed
- Document any guardrail policy changes
- Test in a non-production account first

### ❌ Don't

- Remove guardrail policies completely
- Grant full admin access via guardrails
- Allow destructive operations (delete, terminate)
- Share Chatbot role credentials
- Use the same role for other services

## Monitoring

### Check What Actions Are Being Performed

```bash
# View CloudWatch Logs
aws logs tail /aws/chatbot/AmazonQ-Primary-Account --follow

# Check CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=AmazonQ-Chatbot-Role \
  --max-results 50
```

### Common Log Entries

```json
{
  "eventTime": "2026-05-25T10:30:00Z",
  "eventName": "DescribeInstances",
  "userIdentity": {
    "type": "AssumedRole",
    "principalId": "AROA...:AmazonQ-session",
    "arn": "arn:aws:sts::916657620953:assumed-role/AmazonQ-Chatbot-Role/AmazonQ-session"
  },
  "eventSource": "ec2.amazonaws.com",
  "requestParameters": {...},
  "responseElements": null,
  "sourceIPAddress": "chatbot.amazonaws.com"
}
```

## Summary

| Component | Permission Level | Purpose |
|-----------|------------------|---------|
| IAM Role | AdministratorAccess | Underlying permissions (flexible) |
| Guardrail Policy | ReadOnlyAccess | Actual enforcement (safe) |
| Trust Policy | chatbot.amazonaws.com only | Who can assume role |
| CloudWatch Logs | All actions logged | Audit trail |

**Bottom Line:**
- Role can do anything (theoretically)
- Guardrail restricts to read-only (practically)
- Easy to configure and maintain
- Follows AWS best practices
- Safe by default

---

**For implementation details:** See `cloudformation/amazonq-chatbot-account.yaml`  
**For general documentation:** See `README.md`
