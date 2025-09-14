# PowerShell script to deploy A2AExample to Azure
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = ""
)

Write-Host "🚀 Starting deployment of A2AExample to Azure..." -ForegroundColor Green

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting Azure subscription to: $SubscriptionId" -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
}

# Create resource group if it doesn't exist
Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

# Deploy ARM template
Write-Host "Deploying ARM template..." -ForegroundColor Yellow
$deploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "azuredeploy.json" `
    --parameters "azuredeploy.parameters.json" `
    --parameters environment=$Environment location=$Location `
    --output json | ConvertFrom-Json

if ($deploymentResult.properties.provisioningState -eq "Succeeded") {
    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    
    # Display outputs
    Write-Host "`n📋 Deployment Outputs:" -ForegroundColor Cyan
    Write-Host "Prime Agent URL: $($deploymentResult.properties.outputs.primeAgentUrl.value)" -ForegroundColor White
    Write-Host "Secondary Agent URL: $($deploymentResult.properties.outputs.secondaryAgentUrl.value)" -ForegroundColor White
    Write-Host "Prime Agent Bot Name: $($deploymentResult.properties.outputs.primeAgentBotName.value)" -ForegroundColor White
    Write-Host "Secondary Agent Bot Name: $($deploymentResult.properties.outputs.secondaryAgentBotName.value)" -ForegroundColor White
    
    Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Update azuredeploy.parameters.json with your actual Microsoft App ID, App Password, and OpenAI API Key"
    Write-Host "2. Build and deploy your applications using:"
    Write-Host "   - GitHub Actions (recommended)"
    Write-Host "   - Visual Studio"
    Write-Host "   - Azure CLI: az webapp deployment source config-zip"
    Write-Host "3. Configure bot channels in Azure Portal"
    Write-Host "4. Test the agents in Bot Framework Emulator or Web Chat"
    
} else {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    Write-Host $deploymentResult.properties.error -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 A2AExample deployment script completed!" -ForegroundColor Green