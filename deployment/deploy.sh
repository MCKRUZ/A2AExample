#!/bin/bash

# Bash script to deploy A2AExample to Azure

# Default values
LOCATION="East US"
ENVIRONMENT="dev"
SUBSCRIPTION_ID=""

# Function to display help
show_help() {
    echo "Usage: $0 -g <resource-group-name> [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  -g, --resource-group    Resource group name"
    echo ""
    echo "Optional:"
    echo "  -l, --location         Azure location (default: East US)"
    echo "  -e, --environment      Environment (dev|test|prod) (default: dev)"
    echo "  -s, --subscription     Azure subscription ID"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -g my-a2a-rg -e dev -l \"East US\""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -s|--subscription)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if required parameters are provided
if [ -z "$RESOURCE_GROUP_NAME" ]; then
    echo "❌ Error: Resource group name is required"
    show_help
    exit 1
fi

echo "🚀 Starting deployment of A2AExample to Azure..."

# Set subscription if provided
if [ -n "$SUBSCRIPTION_ID" ]; then
    echo "Setting Azure subscription to: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
fi

# Create resource group if it doesn't exist
echo "Creating resource group: $RESOURCE_GROUP_NAME"
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"

# Deploy ARM template
echo "Deploying ARM template..."
DEPLOYMENT_RESULT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "azuredeploy.json" \
    --parameters "azuredeploy.parameters.json" \
    --parameters environment="$ENVIRONMENT" location="$LOCATION" \
    --output json)

# Check deployment status
PROVISIONING_STATE=$(echo "$DEPLOYMENT_RESULT" | jq -r '.properties.provisioningState')

if [ "$PROVISIONING_STATE" = "Succeeded" ]; then
    echo "✅ Deployment completed successfully!"
    
    # Display outputs
    echo ""
    echo "📋 Deployment Outputs:"
    PRIME_AGENT_URL=$(echo "$DEPLOYMENT_RESULT" | jq -r '.properties.outputs.primeAgentUrl.value')
    SECONDARY_AGENT_URL=$(echo "$DEPLOYMENT_RESULT" | jq -r '.properties.outputs.secondaryAgentUrl.value')
    PRIME_BOT_NAME=$(echo "$DEPLOYMENT_RESULT" | jq -r '.properties.outputs.primeAgentBotName.value')
    SECONDARY_BOT_NAME=$(echo "$DEPLOYMENT_RESULT" | jq -r '.properties.outputs.secondaryAgentBotName.value')
    
    echo "Prime Agent URL: $PRIME_AGENT_URL"
    echo "Secondary Agent URL: $SECONDARY_AGENT_URL"
    echo "Prime Agent Bot Name: $PRIME_BOT_NAME"
    echo "Secondary Agent Bot Name: $SECONDARY_BOT_NAME"
    
    echo ""
    echo "📝 Next Steps:"
    echo "1. Update azuredeploy.parameters.json with your actual Microsoft App ID, App Password, and OpenAI API Key"
    echo "2. Build and deploy your applications using:"
    echo "   - GitHub Actions (recommended)"
    echo "   - Visual Studio"
    echo "   - Azure CLI: az webapp deployment source config-zip"
    echo "3. Configure bot channels in Azure Portal"
    echo "4. Test the agents in Bot Framework Emulator or Web Chat"
    
else
    echo "❌ Deployment failed!"
    echo "$DEPLOYMENT_RESULT" | jq '.properties.error'
    exit 1
fi

echo ""
echo "🎉 A2AExample deployment script completed!"