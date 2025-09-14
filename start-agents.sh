#!/bin/bash

# Bash script to start both agents for Microsoft 365 Agent Playground

echo "🚀 Starting A2AExample agents for Microsoft 365 Agent Playground..."

# Check if .NET 8 is installed
DOTNET_VERSION=$(dotnet --version 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "❌ .NET SDK not found. Please install .NET 8 SDK from https://dotnet.microsoft.com/download"
    exit 1
fi

if [[ ! $DOTNET_VERSION =~ ^8\. ]]; then
    echo "❌ .NET 8 is required. Current version: $DOTNET_VERSION"
    echo "Please install .NET 8 SDK from https://dotnet.microsoft.com/download"
    exit 1
fi

echo "✅ .NET version: $DOTNET_VERSION"

# Build the solution in release mode
echo "🔨 Building solution in Release mode..."
dotnet build --configuration Release
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Function to cleanup background processes
cleanup() {
    echo ""
    echo "🛑 Stopping agents..."
    if [ ! -z "$SECONDARY_PID" ]; then
        kill $SECONDARY_PID 2>/dev/null
    fi
    if [ ! -z "$PRIME_PID" ]; then
        kill $PRIME_PID 2>/dev/null
    fi
    echo "✅ Agents stopped!"
    exit 0
}

# Set trap to cleanup on exit
trap cleanup SIGINT SIGTERM

# Start SecondaryAgent on port 3979
echo "🤖 Starting SecondaryAgent on http://localhost:3979..."
cd SecondaryAgent/SecondaryAgent
dotnet run --configuration Release --urls "http://localhost:3979" &
SECONDARY_PID=$!
cd ../..

# Wait for SecondaryAgent to start
sleep 3

# Start PrimeAgent on port 3978 (Agent Playground default)
echo "🤖 Starting PrimeAgent on http://localhost:3978..."
cd PrimeAgent/PrimeAgent
dotnet run --configuration Release --urls "http://localhost:3978" &
PRIME_PID=$!
cd ../..

# Wait for agents to fully start
sleep 5

echo "✅ Both agents are running!"
echo ""
echo "📋 Agent Endpoints:"
echo "   PrimeAgent:     http://localhost:3978/api/messages"
echo "   SecondaryAgent: http://localhost:3979/api/messages"
echo ""
echo "🎮 Microsoft 365 Agent Playground Setup:"
echo "   1. Install Agent Playground:"
echo "      Linux: curl -sSL https://aka.ms/install-m365agentsplayground | bash"
echo "      NPM:   npm install -g @microsoft/m365agentsplayground"
echo "   2. Connect to PrimeAgent: agentsplayground -e 'http://localhost:3978/api/messages'"
echo "   3. Or use the UI: agentsplayground"
echo ""
echo "💡 Demo Instructions:"
echo "   • Ask PrimeAgent coding questions for direct assistance"
echo "   • Say 'agent' to enable agent-to-agent communication mode"
echo "   • Messages will be forwarded to SecondaryAgent for analysis"
echo "   • Say 'end' to return to normal mode"
echo ""
echo "⏹️  Press Ctrl+C to stop both agents"

# Keep script running
while true; do
    # Check if processes are still running
    if ! kill -0 $PRIME_PID 2>/dev/null || ! kill -0 $SECONDARY_PID 2>/dev/null; then
        echo "❌ One or more agents stopped unexpectedly"
        cleanup
    fi
    sleep 2
done