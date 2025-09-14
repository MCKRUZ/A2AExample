using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Microsoft.SemanticKernel;
using System.Text.Json;

public class PrimeAgentBot : ActivityHandler
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PrimeAgentBot> _logger;
    private readonly IConfiguration _configuration;
    private static Dictionary<string, string> _activeConversations = new();

    public PrimeAgentBot(HttpClient httpClient, ILogger<PrimeAgentBot> logger, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _logger = logger;
        _configuration = configuration;
    }

    protected override async Task OnMembersAddedAsync(IList<ChannelAccount> membersAdded, ITurnContext<IConversationUpdateActivity> turnContext, CancellationToken cancellationToken)
    {
        foreach (var member in membersAdded)
        {
            if (member.Id != turnContext.Activity.Recipient.Id)
            {
                await turnContext.SendActivityAsync("👋 Hello! I'm **PrimeAgent**, a Copilot Pro code agent that can:\n\n" +
                    "• 💻 **Help with coding questions** and programming advice\n" +
                    "• 🤖 **Communicate with other agents** for advanced workflows\n" +
                    "• 🔗 **Work seamlessly** with Microsoft 365 Agent Playground\n\n" +
                    "**Quick Start:**\n" +
                    "• Ask me any coding question\n" +
                    "• Say `agent` to start agent-to-agent communication\n" +
                    "• I can forward your messages to SecondaryAgent for analysis!", 
                    cancellationToken: cancellationToken);
            }
        }
    }

    protected override async Task OnMessageActivityAsync(ITurnContext<IMessageActivity> turnContext, CancellationToken cancellationToken)
    {
        var userMessage = turnContext.Activity.Text?.Trim();
        
        if (string.IsNullOrEmpty(userMessage))
        {
            await turnContext.SendActivityAsync("Please provide a message for me to process.", cancellationToken: cancellationToken);
            return;
        }

        if (userMessage.Equals("agent", StringComparison.OrdinalIgnoreCase))
        {
            await StartAgentConversation(turnContext, cancellationToken);
            return;
        }

        var conversationId = turnContext.Activity.Conversation.Id;
        _logger.LogInformation($"Processing message: '{userMessage}', ConversationId: {conversationId}, ActiveConversations: {string.Join(", ", _activeConversations.Keys)}");
        
        if (_activeConversations.ContainsKey(conversationId))
        {
            _logger.LogInformation($"Forwarding to SecondaryAgent: {userMessage}");
            await ForwardToSecondaryAgent(turnContext, userMessage, cancellationToken);
        }
        else
        {
            _logger.LogInformation($"Processing with Semantic Kernel: {userMessage}");
            await ProcessWithSemanticKernel(turnContext, userMessage, cancellationToken);
        }
    }

    private async Task StartAgentConversation(ITurnContext<IMessageActivity> turnContext, CancellationToken cancellationToken)
    {
        var conversationId = turnContext.Activity.Conversation.Id;
        _activeConversations[conversationId] = "active";
        
        await turnContext.SendActivityAsync("🤖 **Agent-to-Agent Mode Activated!**\n\n" +
            "I'll now forward your messages to the SecondaryAgent for specialized code analysis.", cancellationToken: cancellationToken);
        await turnContext.SendActivityAsync("✨ **Instructions:**\n" +
            "• Type your message to communicate with SecondaryAgent\n" +
            "• Say `end` to return to normal mode\n" +
            "• SecondaryAgent specializes in code analysis and insights!", cancellationToken: cancellationToken);
    }

    private async Task ForwardToSecondaryAgent(ITurnContext<IMessageActivity> turnContext, string message, CancellationToken cancellationToken)
    {
        if (message.Equals("end", StringComparison.OrdinalIgnoreCase))
        {
            _activeConversations.Remove(turnContext.Activity.Conversation.Id);
            await turnContext.SendActivityAsync("🔚 **Agent conversation ended.** I'm back to normal coding assistant mode!", cancellationToken: cancellationToken);
            return;
        }

        // Show forwarding message
        await turnContext.SendActivityAsync($"📤 **PrimeAgent forwarding your message to SecondaryAgent...**\n\n*Original Message:* \"{message}\"", cancellationToken: cancellationToken);

        try
        {
            var secondaryAgentUrl = _configuration["SecondaryAgent:Url"] ?? "http://localhost:3979";
            
            // Create simple echo request
            var echoRequest = new { Message = message };
            var json = JsonSerializer.Serialize(echoRequest, new JsonSerializerOptions 
            { 
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            });
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"{secondaryAgentUrl}/api/echo", content);
            
            if (response.IsSuccessStatusCode)
            {
                var responseContent = await response.Content.ReadAsStringAsync();
                
                // Parse the echo response
                try
                {
                    var echoResponse = JsonSerializer.Deserialize<EchoResponse>(responseContent, new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                    });
                    
                    if (!string.IsNullOrEmpty(echoResponse?.Message))
                    {
                        await turnContext.SendActivityAsync($"📥 **SecondaryAgent Echo Response:**\n\n{echoResponse.Message}", cancellationToken: cancellationToken);
                    }
                    else
                    {
                        await turnContext.SendActivityAsync($"📥 **SecondaryAgent Echo Response:**\n\n{responseContent}", cancellationToken: cancellationToken);
                    }
                }
                catch
                {
                    await turnContext.SendActivityAsync($"📥 **SecondaryAgent Echo Response:**\n\n{responseContent}", cancellationToken: cancellationToken);
                }
            }
            else
            {
                await turnContext.SendActivityAsync($"❌ Failed to communicate with SecondaryAgent. Status: {response.StatusCode}\n" +
                    "Make sure SecondaryAgent is running on port 3979.", cancellationToken: cancellationToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error communicating with SecondaryAgent");
            await turnContext.SendActivityAsync("❌ Error communicating with SecondaryAgent. Please ensure it's running.", cancellationToken: cancellationToken);
        }
    }

    private async Task ProcessWithSemanticKernel(ITurnContext<IMessageActivity> turnContext, string userMessage, CancellationToken cancellationToken)
    {
        try
        {
            var kernel = CreateSemanticKernel();
            var codeAssistantFunction = kernel.CreateFunctionFromPrompt(@"
You are a helpful coding assistant. Analyze the user's request and provide helpful programming advice, 
code snippets, or explanations. Be concise but thorough. Format your response nicely for chat.

User request: {{$input}}");

            var result = await kernel.InvokeAsync(codeAssistantFunction, new() { ["input"] = userMessage });
            
            var response = result.GetValue<string>() ?? "I'm sorry, I couldn't process your request.";
            await turnContext.SendActivityAsync($"💡 **Code Assistant Response:**\n\n{response}", cancellationToken: cancellationToken);
            
            await turnContext.SendActivityAsync("💬 *Say `agent` to start an agent-to-agent conversation for specialized analysis.*", cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing with Semantic Kernel");
            await turnContext.SendActivityAsync("I can help you with coding questions and agent communication. Say `agent` to start agent-to-agent mode.", cancellationToken: cancellationToken);
        }
    }

    private Kernel CreateSemanticKernel()
    {
        var builder = Kernel.CreateBuilder();
        
        var openAiKey = _configuration["OpenAI:ApiKey"];
        if (!string.IsNullOrEmpty(openAiKey))
        {
            builder.AddOpenAIChatCompletion("gpt-3.5-turbo", openAiKey);
        }

        return builder.Build();
    }
}

public class EchoResponse
{
    public string Message { get; set; } = string.Empty;
    public int MessageCount { get; set; }
}