#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Amazon Q Chatbot - Multi-Account Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_FILE="$PROJECT_ROOT/cloudformation/amazonq-chatbot-account.yaml"
STACK_NAME="amazonq-chatbot"
AWS_REGION="us-east-1"

# Function to deploy to an account
deploy_to_account() {
    local account_name=$1
    local param_file=$2

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deploying to: $account_name${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    echo -e "${YELLOW}Current AWS Identity:${NC}"
    aws sts get-caller-identity 2>/dev/null || {
        echo -e "${RED}ERROR: No valid AWS credentials${NC}"
        return 1
    }
    echo ""

    read -p "Deploy to this account? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}Skipping $account_name${NC}"
        echo ""
        return 0
    fi

    echo -e "${BLUE}Checking if stack already exists...${NC}"
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &>/dev/null; then
        echo -e "${YELLOW}Stack exists. Updating...${NC}"
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters "file://$param_file" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION" 2>&1 | grep -v "No updates are to be performed" || echo -e "${YELLOW}No updates needed${NC}"
    else
        echo -e "${BLUE}Creating new stack...${NC}"
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters "file://$param_file" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION"

        echo -e "${BLUE}Waiting for stack creation...${NC}"
        aws cloudformation wait stack-create-complete \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION"
    fi

    echo -e "${GREEN}✅ Deployment complete for $account_name!${NC}"
    echo ""

    # Get outputs
    echo -e "${BLUE}Stack Outputs:${NC}"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
    echo ""
}

# Main
echo -e "${YELLOW}This script will deploy Amazon Q Chatbot to multiple AWS accounts.${NC}"
echo -e "${YELLOW}You'll be prompted before deploying to each account.${NC}"
echo ""
echo -e "${BLUE}Template: ${TEMPLATE_FILE}${NC}"
echo -e "${BLUE}Stack Name: ${STACK_NAME}${NC}"
echo -e "${BLUE}Region: ${AWS_REGION}${NC}"
echo ""

# Check for parameter files
PARAM_DIR="$PROJECT_ROOT/cloudformation/parameters"
if [ ! -d "$PARAM_DIR" ]; then
    echo -e "${RED}ERROR: Parameters directory not found: $PARAM_DIR${NC}"
    exit 1
fi

# List available parameter files
echo -e "${BLUE}Available parameter files:${NC}"
ls -1 "$PARAM_DIR"/*.json 2>/dev/null | grep -v ".example" || {
    echo -e "${YELLOW}No parameter files found. Please create one from the example.${NC}"
    echo ""
    echo "Example:"
    echo "  cd $PARAM_DIR"
    echo "  cp amazonq-chatbot-account.json.example my-account.json"
    echo "  # Edit my-account.json with your values"
    exit 1
}
echo ""

# Prompt for parameter file
read -p "Enter parameter file name (or 'list' to see files): " param_file

if [[ "$param_file" == "list" ]]; then
    ls -1 "$PARAM_DIR"/*.json | grep -v ".example"
    exit 0
fi

# Check if parameter file exists
FULL_PARAM_PATH="$PARAM_DIR/$param_file"
if [ ! -f "$FULL_PARAM_PATH" ]; then
    echo -e "${RED}ERROR: Parameter file not found: $FULL_PARAM_PATH${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Using parameter file: $param_file${NC}"
echo ""

# Deploy
deploy_to_account "Account" "$FULL_PARAM_PATH"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Switch to another AWS account (export AWS_PROFILE=...)"
echo "2. Run this script again to deploy to that account"
echo "3. Test in Slack: @Amazon Q list ec2 instances"
echo ""
echo -e "${YELLOW}Remember: Use the same Slack Workspace ID and Channel ID for all accounts!${NC}"
echo ""
