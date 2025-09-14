# PowerShell script to start both agents locally for testing
Write-Host "🚀 Starting A2AExample agents locally..." -ForegroundColor Green

# Check if .NET 8 is installed
$dotnetVersion = dotnet --version
if (-not $dotnetVersion.StartsWith("8.")) {
    Write-Host "❌ .NET 8 is required. Current version: $dotnetVersion" -ForegroundColor Red
    exit 1
}

Write-Host "✅ .NET version: $dotnetVersion" -ForegroundColor Green

# Build the solution
Write-Host "🔨 Building solution..." -ForegroundColor Yellow
dotnet build --configuration Debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green

# Start SecondaryAgent first (it needs to be running when PrimeAgent starts)
Write-Host "🤖 Starting SecondaryAgent on https://localhost:7002..." -ForegroundColor Yellow
$secondaryJob = Start-Job -ScriptBlock {
    Set-Location "C:\CodeRepos\A2AExample\SecondaryAgent\SecondaryAgent"
    dotnet run --urls "https://localhost:7002"
}

# Wait a moment for SecondaryAgent to start
Start-Sleep -Seconds 3

# Start PrimeAgent
Write-Host "🤖 Starting PrimeAgent on https://localhost:7001..." -ForegroundColor Yellow
$primeJob = Start-Job -ScriptBlock {
    Set-Location "C:\CodeRepos\A2AExample\PrimeAgent\PrimeAgent" 
    dotnet run --urls "https://localhost:7001"
}

Write-Host "✅ Both agents are starting up..." -ForegroundColor Green
Write-Host ""
Write-Host "📋 Service URLs:" -ForegroundColor Cyan
Write-Host "   PrimeAgent:     https://localhost:7001" -ForegroundColor White
Write-Host "   SecondaryAgent: https://localhost:7002" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Bot Framework Emulator URLs:" -ForegroundColor Cyan  
Write-Host "   PrimeAgent:     https://localhost:7001/api/messages" -ForegroundColor White
Write-Host "   SecondaryAgent: https://localhost:7002/api/messages" -ForegroundColor White
Write-Host ""
Write-Host "💡 Testing Tips:" -ForegroundColor Yellow
Write-Host "   1. Use Bot Framework Emulator to connect to PrimeAgent"
Write-Host "   2. Say 'hello' for normal code assistance mode"
Write-Host "   3. Say 'agent' to start agent-to-agent communication"
Write-Host "   4. Send messages that get forwarded to SecondaryAgent"
Write-Host "   5. Say 'end' to stop agent communication"
Write-Host ""
Write-Host "⏹️  Press Ctrl+C to stop both agents" -ForegroundColor Red

# Wait for user to stop
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    Write-Host "`n🛑 Stopping agents..." -ForegroundColor Yellow
    Stop-Job $primeJob, $secondaryJob
    Remove-Job $primeJob, $secondaryJob
    Write-Host "✅ Agents stopped!" -ForegroundColor Green
}