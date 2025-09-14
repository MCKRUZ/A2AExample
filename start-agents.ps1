# PowerShell script to start all A2A agents for Microsoft 365 Agent Playground
Write-Host "🚀 Starting A2AExample agents with A2A protocol enhancements..." -ForegroundColor Green

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

# Start SecondaryAgent on port 3979
Write-Host "🤖 Starting SecondaryAgent on http://localhost:3979..." -ForegroundColor Yellow
$secondaryJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\A2AExample\SecondaryAgent\SecondaryAgent"
    dotnet run --configuration Release --urls "http://localhost:3979"
}

# Start AnalyticsAgent on port 3980 (A2A-enhanced data analysis)
Write-Host "📊 Starting AnalyticsAgent on http://localhost:3980..." -ForegroundColor Yellow
$analyticsJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\A2AExample\AnalyticsAgent\AnalyticsAgent"
    dotnet run --configuration Release --urls "http://localhost:3980"
}

# Start WorkflowAgent on port 3981 (A2A orchestration hub)
Write-Host "🔄 Starting WorkflowAgent on http://localhost:3981..." -ForegroundColor Yellow
$workflowJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\A2AExample\WorkflowAgent\WorkflowAgent"
    dotnet run --configuration Release --urls "http://localhost:3981"
}

# Wait a moment for support agents to start
Start-Sleep -Seconds 4

# Start PrimeAgent on port 3978 (Agent Playground default)
Write-Host "🤖 Starting PrimeAgent on http://localhost:3978..." -ForegroundColor Yellow
$primeJob = Start-Job -ScriptBlock {
    Set-Location "C:\Users\kruz7\OneDrive\Documents\Code Repos\MCKRUZ\A2AExample\PrimeAgent\PrimeAgent"
    dotnet run --configuration Release --urls "http://localhost:3978"
}

# Wait for all agents to fully start
Start-Sleep -Seconds 6

Write-Host "✅ All A2A agents are running!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Agent Endpoints:" -ForegroundColor Cyan
Write-Host "   PrimeAgent:     http://localhost:3978/api/messages (Main Bot)" -ForegroundColor White
Write-Host "   SecondaryAgent: http://localhost:3979/api/messages (Echo Service)" -ForegroundColor White
Write-Host "   AnalyticsAgent: http://localhost:3980/api/messages (Data Analysis)" -ForegroundColor White
Write-Host "   WorkflowAgent:  http://localhost:3981/api/messages (A2A Orchestration)" -ForegroundColor White
Write-Host ""
Write-Host "🔗 A2A Protocol Endpoints:" -ForegroundColor Cyan
Write-Host "   AnalyticsAgent JSON-RPC: http://localhost:3980/api/rpc" -ForegroundColor White
Write-Host "   AnalyticsAgent Card:     http://localhost:3980/agent-card" -ForegroundColor White
Write-Host "   WorkflowAgent Card:      http://localhost:3981/agent-card" -ForegroundColor White
Write-Host "   Agent Discovery:         http://localhost:3981/api/discovery/agents" -ForegroundColor White
Write-Host ""
Write-Host "🎮 Microsoft 365 Agent Playground Setup:" -ForegroundColor Cyan
Write-Host "   1. Install Agent Playground: winget install agentsplayground" -ForegroundColor White
Write-Host "   2. Connect to PrimeAgent: agentsplayground -e 'http://localhost:3978/api/messages'" -ForegroundColor White
Write-Host "   3. Or try WorkflowAgent: agentsplayground -e 'http://localhost:3981/api/messages'" -ForegroundColor White
Write-Host ""
Write-Host "💡 A2A Demo Instructions:" -ForegroundColor Yellow
Write-Host "   • PrimeAgent: Ask coding questions, say 'agent' for A2A mode" -ForegroundColor White
Write-Host "   • AnalyticsAgent: Send JSON data or 'analyze [request]'" -ForegroundColor White
Write-Host "   • WorkflowAgent: Say 'workflow [task]' for multi-agent orchestration" -ForegroundColor White
Write-Host "   • Try 'agents', 'discover', 'capabilities' for A2A features" -ForegroundColor White
Write-Host ""
Write-Host "⏹️  Press Ctrl+C to stop all agents" -ForegroundColor Red

# Keep script running and monitor jobs
try {
    while ($true) {
        # Check if jobs are still running
        $allJobs = @($primeJob, $secondaryJob, $analyticsJob, $workflowJob)
        $failedJobs = $allJobs | Where-Object { $_.State -eq "Failed" }

        if ($failedJobs.Count -gt 0) {
            Write-Host "❌ One or more agents failed to start. Check the logs above." -ForegroundColor Red
            Write-Host "Failed jobs: $($failedJobs.Count)/$($allJobs.Count)" -ForegroundColor Red
            break
        }
        Start-Sleep -Seconds 2
    }
}
finally {
    Write-Host "`n🛑 Stopping all A2A agents..." -ForegroundColor Yellow
    Stop-Job $primeJob, $secondaryJob, $analyticsJob, $workflowJob -ErrorAction SilentlyContinue
    Remove-Job $primeJob, $secondaryJob, $analyticsJob, $workflowJob -ErrorAction SilentlyContinue
    Write-Host "✅ All agents stopped!" -ForegroundColor Green
}