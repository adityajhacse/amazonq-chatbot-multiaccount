# Slack Workspace Setup Guide

## Overview

Before deploying Amazon Q Chatbot to any AWS account, you must **authorize your Slack workspace with AWS Chatbot in that specific account**. This is a **manual process per AWS account** that **cannot be automated**.

## Why This Cannot Be Automated

The Slack authorization process uses **OAuth 2.0**, which requires:
- Interactive browser-based authentication
- User consent in the Slack UI
- Secure token exchange between Slack and AWS

AWS does not provide an API or CLI method to automate this step for security reasons.

## Important Facts

⚠️ Must be done **ONCE per AWS account** (not just once total)  
✅ The **Workspace ID stays the same** across all accounts  
✅ Each account gets its own **OAuth authorization token**  
✅ Takes about **2 minutes per account**  
✅ Once done for an account, that account's deployment is fully automated  

---

## Step-by-Step Authorization Process

**IMPORTANT:** Repeat these steps for **EACH AWS account** where you want to deploy Amazon Q Chatbot.

### Step 1: Access AWS Chatbot Console

1. **Log in to AWS Console**
   - Log into the **SPECIFIC AWS account** you're deploying to
   - Region doesn't matter for this step

2. **Navigate to AWS Chatbot**
   - Search for "Chatbot" in the AWS services search
   - Or go to: https://console.aws.amazon.com/chatbot/

### Step 2: Configure Slack Client

1. Click **"Configure new client"** or **"Configure a chat client"**

2. Select **"Slack"** as the chat client

3. Click **"Configure client"** button

   ![Configure Slack](https://docs.aws.amazon.com/chatbot/latest/adminguide/images/configure-slack.png)

### Step 3: Authorize in Slack

1. You'll be **redirected to Slack** in your browser

2. **Sign in to Slack** (if not already signed in)

3. **Review the permissions** AWS Chatbot is requesting:
   - Post messages to channels
   - Read channel information
   - Access workspace information

4. **Select your workspace** from the dropdown (if you have multiple)

5. Click **"Allow"** to authorize AWS Chatbot

   ```
   AWS Chatbot is requesting permission to access the [Your Workspace] workspace.
   
   AWS Chatbot will be able to:
   - Send messages and replies
   - View information about messages and channels
   - Perform actions in Slack
   
   [Cancel] [Allow]
   ```

### Step 4: Get Your Workspace ID

1. After authorization, you'll be redirected back to AWS Console

2. You'll see your **authorized workspace** listed

3. Note the **Workspace ID** (format: `T0XXXXXXXXX`)
   - Example: `T04SR5XV56X`
   - **This ID will be the SAME across all AWS accounts**

4. **Save this Workspace ID** - you'll use it for all account deployments

   ```
   Authorized Workspaces
   
   Workspace Name          Workspace ID      Status
   Your Company Slack      T04SR5XV56X      Authorized
   ```

**Key Point:** The Workspace ID (T04SR5XV56X) is the same in every account, but the authorization token stored in each account is unique.

### Step 5: Get Your Channel ID

1. **In Slack**, go to the channel you want to use (e.g., `#amazonq-multi-account`)

2. **Right-click** on the channel name in the left sidebar

3. Select **"View channel details"**

4. Scroll to the bottom of the details panel

5. You'll see the **Channel ID** (format: `C0XXXXXXXXX`)
   - Example: `C0B5UE340PP`

6. **Copy this Channel ID** - you'll need it for all deployments

   ```
   Channel details
   
   About
   Description: Amazon Q multi-account queries
   
   Channel ID: C0B5UE340PP
   ```

---

## Verification

After completing authorization, verify it worked:

```bash
# List authorized workspaces (from any AWS account)
aws chatbot list-microsoft-teams-channel-configurations

# Or check in AWS Console
# AWS Chatbot → Configured clients → Should show your Slack workspace
```

---

## Using the IDs for Deployment

Once you have both IDs, create your parameter file:

```json
[
  {
    "ParameterKey": "SlackWorkspaceId",
    "ParameterValue": "T04SR5XV56X"          ← Your Workspace ID
  },
  {
    "ParameterKey": "SlackChannelId",
    "ParameterValue": "C0B5UE340PP"          ← Your Channel ID
  },
  {
    "ParameterKey": "ConfigurationName",
    "ParameterValue": "AmazonQ-Production"
  },
  {
    "ParameterKey": "AccountNickname",
    "ParameterValue": "Production"
  }
]
```

**Important:**
- Use the **same Workspace ID and Channel ID** for all AWS accounts
- Only change `ConfigurationName` and `AccountNickname` per account
- **Remember:** Even though the IDs are the same, you must authorize in each account separately before deploying

---

## Troubleshooting

### Issue: "Workspace not authorized" during CloudFormation deployment

**Error Message:**
```
Unable to create the configuration because Slack workspace T04SR5XV56X 
is not authorized with AWS account XXXXXXXXXXXX
```

**Solution:**
This means you haven't authorized the Slack workspace **in this specific AWS account** yet.

1. Log into the **specific AWS account** mentioned in the error (XXXXXXXXXXXX)
2. Go to AWS Chatbot console in that account
3. Check if your workspace is listed under "Configured clients"
4. If not, repeat the authorization steps above **for this account**
5. Delete the failed CloudFormation stack
6. Re-deploy the CloudFormation stack

**Common mistake:** You authorized in account A, but you're trying to deploy to account B. Each account needs its own authorization.

### Issue: "You don't have permission to authorize"

**Solution:**
- You need **Slack Workspace Admin** permissions
- Contact your Slack workspace admin to authorize
- Or ask them to make you an admin temporarily

### Issue: "Cannot find Channel ID"

**Solution:**
1. Make sure you're right-clicking the correct channel
2. For **private channels**: The bot must be a member first
3. Try making the channel public (easier for setup)

### Issue: "Authorization page doesn't load"

**Solution:**
1. Check your browser allows popups from AWS Console
2. Try a different browser (Chrome/Firefox recommended)
3. Disable browser extensions that might block redirects

### Issue: "Want to use a different workspace"

**Solution:**
1. Go to AWS Chatbot console
2. Under "Configured clients", find your workspace
3. Click "Remove" to revoke authorization
4. Repeat authorization steps with the correct workspace

---

## For Multiple Workspaces

If you have multiple Slack workspaces:

1. **Authorize each workspace separately** (repeat Steps 1-4 for each)
2. Each workspace gets its own Workspace ID
3. You can deploy to different accounts using different workspaces
4. Each workspace can have its own set of channels

---

## Security Notes

### What AWS Chatbot Can Do

After authorization, AWS Chatbot can:
- ✅ Post messages to channels (responses to your queries)
- ✅ Read channel information (to verify bot membership)
- ✅ List users and channels (for permissions)

### What AWS Chatbot CANNOT Do

- ❌ Read message history (except messages directed to the bot)
- ❌ Read private messages between users
- ❌ Access files or documents
- ❌ Modify workspace settings
- ❌ Remove or add users

### Revoking Access

If you need to revoke AWS Chatbot's access:

1. **In Slack:**
   - Go to Workspace Settings → Apps
   - Find "AWS Chatbot"
   - Click "Remove App"

2. **In AWS:**
   - Go to AWS Chatbot console
   - Configured clients → Select workspace
   - Click "Remove"

---

## Next Steps

After completing Slack authorization **for a specific AWS account**:

1. ✅ You have your Workspace ID (e.g., `T04SR5XV56X`) - same for all accounts
2. ✅ You have your Channel ID (e.g., `C0B5UE340PP`) - same for all accounts
3. ✅ This AWS account is now authorized to use the Slack workspace
4. ➡️ Proceed to deploy CloudFormation stack to **this** AWS account
5. ➡️ **Repeat Steps 1-4** for each additional AWS account you want to deploy to
6. ➡️ See README.md for deployment instructions

---

## Summary

| Step | Action | Time | Per Account? |
|------|--------|------|--------------|
| 1 | Authorize Slack workspace in account | 2 min | ✅ Yes |
| 2 | Get Workspace ID (first time only) | 30 sec | ❌ No |
| 3 | Get Channel ID (first time only) | 30 sec | ❌ No |
| 4 | Deploy CloudFormation to account | 5 min | ✅ Yes |
| 5 | Test in Slack | 1 min | ❌ No |

**First account setup:** ~8 minutes (authorize + get IDs + deploy)  
**Each additional account:** ~7 minutes (authorize + deploy)  
**For 3 accounts total:** ~22 minutes

**Key takeaway:** Authorization (Steps 1) must be done per account. IDs (Steps 2-3) are retrieved once and reused.

---

**Questions?** See README.md troubleshooting section or check AWS Chatbot documentation.
