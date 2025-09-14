#Requires -RunAsAdministrator

# PowerShell script for automated setup of A2A Example project
# This script installs prerequisites, builds the solution, and starts everything

param(
    [switch]$SkipPlayground,
    [switch]$NoInteractive
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 A2A Example - Automated Setup Script" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Function to check if a command exists
function Test-CommandExists {
    param($Command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "stop"
    try {
        if (Get-Command $Command -ErrorAction Stop) { return $true }
    }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Function to wait for user input if not in non-interactive mode
function Wait-ForUser {
    param($Message = "Press Enter to continue...")
    if (!$NoInteractive) {
        Write-Host $Message -ForegroundColor Yellow
        Read-Host
    }
}

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script must be run as Administrator for winget installations!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green

# Step 1: Check and install .NET 8 SDK
Write-Host "`n📦 Step 1: Checking .NET 8 SDK..." -ForegroundColor Cyan

if (Test-CommandExists "dotnet") {
    $dotnetVersion = dotnet --version
    $majorVersion = [int]($dotnetVersion.Split('.')[0])
    if ($majorVersion -ge 8) {
        Write-Host "✅ .NET SDK version $dotnetVersion is already installed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  .NET version $dotnetVersion found, but version 8+ required" -ForegroundColor Yellow
        Write-Host "📦 Installing .NET 8 SDK..." -ForegroundColor Yellow
        winget install Microsoft.DotNet.SDK.8 --accept-package-agreements --accept-source-agreements
        Write-Host "✅ .NET 8 SDK installed!" -ForegroundColor Green
    }
} else {
    Write-Host "📦 .NET not found. Installing .NET 8 SDK..." -ForegroundColor Yellow
    winget install Microsoft.DotNet.SDK.8 --accept-package-agreements --accept-source-agreements
    Write-Host "✅ .NET 8 SDK installed!" -ForegroundColor Green

    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# Step 2: Check and install Microsoft 365 Agent Playground
Write-Host "`n🎮 Step 2: Checking Microsoft 365 Agent Playground..." -ForegroundColor Cyan

if (Test-CommandExists "agentsplayground") {
    Write-Host "✅ Agent Playground is already installed" -ForegroundColor Green
} else {
    Write-Host "📦 Installing Microsoft 365 Agent Playground..." -ForegroundColor Yellow
    try {
        winget install agentsplayground --accept-package-agreements --accept-source-agreements
        Write-Host "✅ Agent Playground installed!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Failed to install via winget. Trying npm fallback..." -ForegroundColor Yellow
        if (Test-CommandExists "npm") {
            npm install -g @microsoft/m365agentsplayground
            Write-Host "✅ Agent Playground installed via npm!" -ForegroundColor Green
        } else {
            Write-Host "❌ Could not install Agent Playground. Please install Node.js and run:" -ForegroundColor Red
            Write-Host "   npm install -g @microsoft/m365agentsplayground" -ForegroundColor Yellow
            Wait-ForUser "Press Enter to continue anyway..."
        }
    }

    # Refresh environment variables
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# Step 3: Build the solution
Write-Host "`n🔨 Step 3: Building the solution..." -ForegroundColor Cyan

# Check if we're in the right directory
if (!(Test-Path "A2AExample.sln")) {
    Write-Host "❌ A2AExample.sln not found in current directory!" -ForegroundColor Red
    Write-Host "   Please run this script from the A2AExample project root directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "🏗️  Building solution..." -ForegroundColor Yellow
dotnet build A2AExample.sln --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    Write-Host "   Check the error messages above and fix any issues." -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Solution built successfully!" -ForegroundColor Green

# Step 4: Start the agents
Write-Host "`n🤖 Step 4: Starting the agents..." -ForegroundColor Cyan

Write-Host "🚀 Starting SecondaryAgent on port 3979..." -ForegroundColor Yellow
$secondaryJob = Start-Job -ScriptBlock {
    param($ProjectPath)
    Set-Location $ProjectPath
    dotnet run --project SecondaryAgent/SecondaryAgent/SecondaryAgent.csproj --configuration Release --urls "http://localhost:3979"
} -ArgumentList (Get-Location).Path

Start-Sleep -Seconds 3

Write-Host "🚀 Starting PrimeAgent on port 3978..." -ForegroundColor Yellow
$primeJob = Start-Job -ScriptBlock {
    param($ProjectPath)
    Set-Location $ProjectPath
    dotnet run --project PrimeAgent/PrimeAgent/PrimeAgent.csproj --configuration Release --urls "http://localhost:3978"
} -ArgumentList (Get-Location).Path

Write-Host "⏱️  Waiting for agents to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Check if jobs are running
if ($primeJob.State -eq "Running" -and $secondaryJob.State -eq "Running") {
    Write-Host "✅ Both agents are running!" -ForegroundColor Green
} else {
    Write-Host "⚠️  One or both agents may have failed to start. Check the output above." -ForegroundColor Yellow
}

# Step 5: Start Agent Playground (optional)
if (!$SkipPlayground) {
    Write-Host "`n🎮 Step 5: Starting Agent Playground..." -ForegroundColor Cyan

    if (Test-CommandExists "agentsplayground") {
        Write-Host "🚀 Launching Agent Playground..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2

        $playgroundJob = Start-Job -ScriptBlock {
            agentsplayground -e "http://localhost:3978/api/messages"
        }

        Start-Sleep -Seconds 5
        Write-Host "✅ Agent Playground should be starting!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Agent Playground not available. Skipping..." -ForegroundColor Yellow
    }
}

# Final status and instructions
Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Green

Write-Host "`n📋 What's Running:" -ForegroundColor Cyan
Write-Host "   PrimeAgent:     http://localhost:3978/api/messages" -ForegroundColor White
Write-Host "   SecondaryAgent: http://localhost:3979/api/messages" -ForegroundColor White
if (!$SkipPlayground -and (Test-CommandExists "agentsplayground")) {
    Write-Host "   Agent Playground: Check console for web URL (usually http://localhost:6xxxx)" -ForegroundColor White
}

Write-Host "`n🎮 How to Test:" -ForegroundColor Cyan
if (!$SkipPlayground -and (Test-CommandExists "agentsplayground")) {
    Write-Host "   1. Open the Agent Playground URL in your browser" -ForegroundColor White
    Write-Host "   2. Start chatting with PrimeAgent" -ForegroundColor White
    Write-Host "   3. Try saying 'agent' to enable agent-to-agent mode" -ForegroundColor White
    Write-Host "   4. Say 'end' to return to normal mode" -ForegroundColor White
} else {
    Write-Host "   1. Run manually: agentsplayground -e 'http://localhost:3978/api/messages'" -ForegroundColor White
    Write-Host "   2. Open the playground URL in your browser" -ForegroundColor White
    Write-Host "   3. Start chatting with PrimeAgent" -ForegroundColor White
}

Write-Host "`n🛑 To Stop Everything:" -ForegroundColor Yellow
Write-Host "   Press Ctrl+C or close this PowerShell window" -ForegroundColor White

# Keep script running and monitor jobs
Write-Host "`n⏹️  Press Ctrl+C to stop all agents and exit" -ForegroundColor Red
Write-Host "   Monitoring agents..." -ForegroundColor Gray

try {
    while ($true) {
        # Check if jobs are still running
        if ($primeJob.State -ne "Running" -or $secondaryJob.State -ne "Running") {
            Write-Host "`n❌ One or more agents stopped unexpectedly!" -ForegroundColor Red

            if ($primeJob.State -ne "Running") {
                Write-Host "PrimeAgent Job State: $($primeJob.State)" -ForegroundColor Yellow
                if ($primeJob.State -eq "Failed") {
                    Write-Host "PrimeAgent Error:" -ForegroundColor Red
                    Receive-Job $primeJob | Write-Host
                }
            }

            if ($secondaryJob.State -ne "Running") {
                Write-Host "SecondaryAgent Job State: $($secondaryJob.State)" -ForegroundColor Yellow
                if ($secondaryJob.State -eq "Failed") {
                    Write-Host "SecondaryAgent Error:" -ForegroundColor Red
                    Receive-Job $secondaryJob | Write-Host
                }
            }
            break
        }
        Start-Sleep -Seconds 2
    }
}
catch [System.Management.Automation.PipelineStoppedException] {
    Write-Host "`n🛑 Stopping agents..." -ForegroundColor Yellow
}
finally {
    # Cleanup
    if ($primeJob) {
        Stop-Job $primeJob -ErrorAction SilentlyContinue
        Remove-Job $primeJob -ErrorAction SilentlyContinue
    }
    if ($secondaryJob) {
        Stop-Job $secondaryJob -ErrorAction SilentlyContinue
        Remove-Job $secondaryJob -ErrorAction SilentlyContinue
    }
    if ($playgroundJob) {
        Stop-Job $playgroundJob -ErrorAction SilentlyContinue
        Remove-Job $playgroundJob -ErrorAction SilentlyContinue
    }

    Write-Host "✅ All agents stopped. Setup script complete!" -ForegroundColor Green
}