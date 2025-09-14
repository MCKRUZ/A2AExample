# A2A Example - Agent-to-Agent Communication Demo

A demonstration of Microsoft Bot Framework agents that can communicate with each other using Microsoft 365 Agent Playground for testing.

## 🏗️ Architecture

This solution contains two Bot Framework agents:
- **PrimeAgent** (Port 3978) - Main agent that handles user interactions and can forward messages to SecondaryAgent
- **SecondaryAgent** (Port 3979) - Secondary agent that processes forwarded messages and returns analysis

## 📋 Prerequisites

### Required Software
- **Windows 10/11** (recommended)
- **.NET 8.0 SDK** or higher ([Download here](https://dotnet.microsoft.com/download))
- **Visual Studio 2022** (optional, for development)
- **PowerShell 5.1+** (usually pre-installed on Windows)

### Package Managers (choose one)
- **winget** (recommended, pre-installed on Windows 11)
- **npm** (if you prefer npm installation)

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)
1. Clone/download this repository
2. Open PowerShell as Administrator in the project directory
3. Run the setup script:
   ```powershell
   .\setup.ps1
   ```
4. The script will:
   - Install .NET 8 SDK (if needed)
   - Install Microsoft 365 Agent Playground
   - Build the solution
   - Start both agents
   - Launch the Agent Playground

### Option 2: Manual Setup

#### 1. Install Prerequisites
```powershell
# Install .NET 8 SDK (if not already installed)
winget install Microsoft.DotNet.SDK.8

# Install Microsoft 365 Agent Playground
winget install agentsplayground
```

#### 2. Build the Solution
```bash
dotnet build A2AExample.sln
```

#### 3. Start the Agents
```powershell
# Option A: Use the startup script
.\start-agents.ps1

# Option B: Manual startup
# Terminal 1 - Start SecondaryAgent
dotnet run --project SecondaryAgent/SecondaryAgent/SecondaryAgent.csproj --urls "http://localhost:3979"

# Terminal 2 - Start PrimeAgent
dotnet run --project PrimeAgent/PrimeAgent/PrimeAgent.csproj --urls "http://localhost:3978"
```

#### 4. Connect Agent Playground
```bash
# Connect to PrimeAgent
agentsplayground -e "http://localhost:3978/api/messages"
```

## 🎮 How to Use

### Agent Playground Interface
1. Open your browser to the URL shown in the Agent Playground console (usually `http://localhost:6xxxx`)
2. Start chatting with the PrimeAgent

### Available Commands
- **Normal Chat**: Ask coding questions directly to PrimeAgent
- **"agent"**: Enable agent-to-agent communication mode
- **"end"**: Return to normal direct communication mode

### Demo Flow
1. Start with normal questions: *"How do I create a REST API in .NET?"*
2. Switch to agent mode: *"agent"*
3. Ask complex questions: *"Analyze the best practices for microservices architecture"*
4. Messages will be forwarded to SecondaryAgent for analysis
5. Return to normal mode: *"end"*

## 🛠️ Development

### Project Structure
```
A2AExample/
├── PrimeAgent/
│   └── PrimeAgent/           # Main agent (.NET 8 Web API)
├── SecondaryAgent/
│   └── SecondaryAgent/       # Secondary agent (.NET 8 Web API)
├── start-agents.ps1          # PowerShell startup script
├── start-agents.sh           # Bash startup script (Linux/Mac)
├── setup.ps1                 # Automated setup script
└── A2AExample.sln            # Visual Studio solution
```

### Running in Visual Studio
1. Open `A2AExample.sln` in Visual Studio 2022
2. Set either `PrimeAgent` or `SecondaryAgent` as the startup project
3. Press F5 to run/debug
4. For both agents: right-click solution → "Set Startup Projects" → "Multiple startup projects"

### Configuration
Both agents are configured to:
- Use .NET 8.0
- Run without AppHost (to avoid OneDrive sync issues)
- Use Bot Framework 4.21.1
- Include Semantic Kernel 1.0.1

## 🔧 Troubleshooting

### Common Issues

**Build Errors (AppHost access denied)**
- Fixed by setting `<UseAppHost>false</UseAppHost>` in project files

**Port Already in Use**
- Kill existing processes: `taskkill /f /im dotnet.exe`
- Or change ports in the startup scripts

**Agent Playground Connection Issues**
- Ensure agents are running before starting playground
- Check that ports 3978 and 3979 are available
- Verify endpoints: `http://localhost:3978/api/messages`

**OneDrive Sync Issues**
- The solution is configured to avoid OneDrive file lock issues
- If problems persist, move project outside OneDrive folder

### Manual Agent Testing
You can test agents directly without the playground:
```bash
# Test PrimeAgent health
curl http://localhost:3978/api/health

# Test SecondaryAgent health
curl http://localhost:3979/api/health
```

## 📝 Scripts Reference

### start-agents.ps1
- Builds solution in Release mode
- Starts both agents in background jobs
- Provides connection instructions
- Handles cleanup on exit

### setup.ps1
- Checks and installs prerequisites
- Builds solution
- Starts agents and playground
- One-command setup for new machines

### start-agents.sh
- Linux/Mac version of the startup script
- Same functionality as PowerShell version

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with both agents running
5. Submit a pull request

## 📄 License

This is a demonstration project. Use as reference for your own implementations.

## 🆘 Support

For issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Ensure ports 3978/3979 are available
4. Check agent logs for error messages

**Endpoints:**
- PrimeAgent: `http://localhost:3978/api/messages`
- SecondaryAgent: `http://localhost:3979/api/messages`
- Agent Playground: `http://localhost:6xxxx` (port varies)