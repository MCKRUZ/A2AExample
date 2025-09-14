# PowerShell script to start both agents for Microsoft 365 Agent Playground
Write-Host "🚀 Starting A2AExample agents for Microsoft 365 Agent Playground..." -ForegroundColor Green

# Check if .NET 8 or higher is installed
$dotnetVersion = dotnet --version
$majorVersion = [int]($dotnetVersion.Split('.')[0])
if ($majorVersion -lt 8) {
    Write-Host "❌ .NET 8 or higher is required. Current version: $dotnetVersion" -ForegroundColor Red
    Write-Host "Please install .NET 8+ SDK from https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ .NET version: $dotnetVersion" -ForegroundColor Green

# Build the solution in release mode to avoid file access issues
Write-Host "🔨 Building solution in Release mode..." -ForegroundColor Yellow
dotnet build --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green

# Start SecondaryAgent first on port 3979
Write-Host "🤖 Starting SecondaryAgent on http://localhost:3979..." -ForegroundColor Yellow
$secondaryJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\A2AExample\SecondaryAgent\SecondaryAgent"
    dotnet run --configuration Release --urls "http://localhost:3979"
}

# Wait a moment for SecondaryAgent to start
Start-Sleep -Seconds 3

# Start PrimeAgent on port 3978 (Agent Playground default)
Write-Host "🤖 Starting PrimeAgent on http://localhost:3978..." -ForegroundColor Yellow
$primeJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\A2AExample\PrimeAgent\PrimeAgent"
    dotnet run --configuration Release --urls "http://localhost:3978"
}

# Wait for agents to fully start
Start-Sleep -Seconds 5

Write-Host "✅ Both agents are running!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Agent Endpoints:" -ForegroundColor Cyan
Write-Host "   PrimeAgent:     http://localhost:3978/api/messages" -ForegroundColor White
Write-Host "   SecondaryAgent: http://localhost:3979/api/messages" -ForegroundColor White
Write-Host ""
Write-Host "🎮 Microsoft 365 Agent Playground Setup:" -ForegroundColor Cyan
Write-Host "   1. Install Agent Playground: winget install agentsplayground" -ForegroundColor White
Write-Host "   2. Connect to PrimeAgent: agentsplayground -e 'http://localhost:3978/api/messages'" -ForegroundColor White
Write-Host "   3. Or use the UI: agentsplayground" -ForegroundColor White
Write-Host ""
Write-Host "💡 Demo Instructions:" -ForegroundColor Yellow
Write-Host "   • Ask PrimeAgent coding questions for direct assistance" -ForegroundColor White
Write-Host "   • Say 'agent' to enable agent-to-agent communication mode" -ForegroundColor White
Write-Host "   • Messages will be forwarded to SecondaryAgent for analysis" -ForegroundColor White
Write-Host "   • Say 'end' to return to normal mode" -ForegroundColor White
Write-Host ""
Write-Host "⏹️  Press Ctrl+C to stop both agents" -ForegroundColor Red

# Keep script running and monitor jobs
try {
    while ($true) {
        # Check if jobs are still running
        if ($primeJob.State -eq "Failed" -or $secondaryJob.State -eq "Failed") {
            Write-Host "❌ One or more agents failed to start. Check the logs above." -ForegroundColor Red
            break
        }
        Start-Sleep -Seconds 2
    }
}
finally {
    Write-Host "`n🛑 Stopping agents..." -ForegroundColor Yellow
    Stop-Job $primeJob, $secondaryJob -ErrorAction SilentlyContinue
    Remove-Job $primeJob, $secondaryJob -ErrorAction SilentlyContinue
    Write-Host "✅ Agents stopped!" -ForegroundColor Green
}