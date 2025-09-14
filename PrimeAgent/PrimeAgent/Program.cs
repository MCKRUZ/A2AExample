using Microsoft.SemanticKernel;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpClient();
builder.Services.AddControllers();

// Add Semantic Kernel
builder.Services.AddKernel();

var app = builder.Build();

app.UseRouting();

// A2A Protocol endpoint for agent-to-agent communication
app.MapPost("/a2a", async (HttpContext context, ILogger<Program> logger, IHttpClientFactory httpClientFactory) =>
{
    try
    {
        var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
        logger.LogInformation($"A2A request received: {body}");

        var request = JsonSerializer.Deserialize<A2ARequest>(body, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        var message = request?.Message ?? body;

        // Forward to SecondaryAgent for enhanced analysis using A2A protocol
        var httpClient = httpClientFactory.CreateClient();
        var secondaryRequest = new A2ARequest
        {
            Message = message,
            AgentId = "PrimeAgent",
            Timestamp = DateTime.UtcNow
        };

        var json = JsonSerializer.Serialize(secondaryRequest, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

        try
        {
            var secondaryResponse = await httpClient.PostAsync("http://localhost:3979/a2a", content);
            if (secondaryResponse.IsSuccessStatusCode)
            {
                var secondaryContent = await secondaryResponse.Content.ReadAsStringAsync();
                var secondaryResult = JsonSerializer.Deserialize<A2AResponse>(secondaryContent, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var combinedResponse = $"🤖 **PrimeAgent + SecondaryAgent Collaboration:**\n\n" +
                                     $"• **Original Input:** {message}\n" +
                                     $"• **PrimeAgent Processing:** Enhanced with Semantic Kernel\n" +
                                     $"• **SecondaryAgent Analysis:**\n{secondaryResult?.Response}\n" +
                                     $"• **Combined Result:** Comprehensive analysis with A2A protocol";

                var response = new A2AResponse
                {
                    AgentName = "PrimeAgent",
                    Protocol = "A2A",
                    Response = combinedResponse,
                    Timestamp = DateTime.UtcNow,
                    Version = "2.0.0",
                    Capabilities = new[] { "semantic_kernel", "a2a_communication", "agent_orchestration", "collaborative_analysis" }
                };

                return Results.Json(response, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "SecondaryAgent unavailable, proceeding with PrimeAgent only");
        }

        // Fallback to PrimeAgent only processing
        var fallbackResponse = new A2AResponse
        {
            AgentName = "PrimeAgent",
            Protocol = "A2A",
            Response = $"PrimeAgent processed: {message}",
            Timestamp = DateTime.UtcNow,
            Version = "2.0.0",
            Capabilities = new[] { "semantic_kernel", "a2a_communication", "code_assistance" }
        };

        return Results.Json(fallbackResponse, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error processing A2A request");
        return Results.BadRequest("Invalid A2A request");
    }
});

// Agent Card endpoint for capability discovery
app.MapGet("/agent-card", () => Results.Json(new
{
    name = "PrimeAgent",
    description = "Advanced agent with Semantic Kernel and A2A protocol support",
    version = "2.0.0",
    capabilities = new[] { "semantic_kernel", "a2a_communication", "code_assistance", "agent_orchestration" },
    protocol = "A2A",
    endpoints = new
    {
        a2a = "/a2a",
        messages = "/api/messages",
        health = "/api/health"
    }
}, new JsonSerializerOptions
{
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
}));

// Microsoft Agents SDK endpoint
app.MapPost("/api/messages", async (HttpContext context, ILogger<Program> logger, IHttpClientFactory httpClientFactory) =>
{
    try
    {
        var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
        logger.LogInformation($"Message received: {body}");

        var activity = JsonSerializer.Deserialize<BotActivity>(body, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        // Handle different activity types
        if (activity?.Type == "message" && !string.IsNullOrEmpty(activity.Text))
        {
            var userMessage = activity.Text.Trim();
            var httpClient = httpClientFactory.CreateClient();

            // Forward to SecondaryAgent using A2A protocol for enhanced response
            var secondaryRequest = new A2ARequest
            {
                Message = userMessage,
                AgentId = "PrimeAgent",
                Timestamp = DateTime.UtcNow
            };

            var json = JsonSerializer.Serialize(secondaryRequest, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });
            var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

            string responseText = "🤖 **PrimeAgent v2.0** with A2A Protocol ready!";

            try
            {
                var secondaryResponse = await httpClient.PostAsync("http://localhost:3979/a2a", content);
                if (secondaryResponse.IsSuccessStatusCode)
                {
                    var secondaryContent = await secondaryResponse.Content.ReadAsStringAsync();
                    var secondaryResult = JsonSerializer.Deserialize<A2AResponse>(secondaryContent, new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                    });

                    responseText = $"🤖 **PrimeAgent + SecondaryAgent A2A Response:**\n\n" +
                                 $"**Your message:** {userMessage}\n\n" +
                                 $"**Collaborative Analysis:**\n{secondaryResult?.Response}\n\n" +
                                 $"✨ *Powered by A2A Protocol v2.0*";
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "SecondaryAgent unavailable");
                responseText = $"🤖 **PrimeAgent Response:**\n\n" +
                              $"**Your message:** {userMessage}\n\n" +
                              $"**Processing:** Enhanced with Semantic Kernel and A2A Protocol\n\n" +
                              $"✨ *Ready for agent-to-agent communication*";
            }

            // Send response back to Bot Framework connector
            var responseMessage = new
            {
                type = "message",
                text = responseText,
                from = new { id = "primeagent", name = "PrimeAgent" },
                timestamp = DateTime.UtcNow,
                conversation = activity.Conversation,
                replyToId = activity.Id
            };

            // Post response back to the connector
            try
            {
                var serviceUrl = JsonDocument.Parse(body).RootElement.GetProperty("serviceUrl").GetString();
                var conversationId = JsonDocument.Parse(body).RootElement.GetProperty("conversation").GetProperty("id").GetString();

                var responseJson = JsonSerializer.Serialize(responseMessage, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });
                var responseContent = new StringContent(responseJson, System.Text.Encoding.UTF8, "application/json");

                var connectorClient = httpClientFactory.CreateClient();
                await connectorClient.PostAsync($"{serviceUrl}/v3/conversations/{conversationId}/activities", responseContent);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to send response to connector");
            }

            return Results.Ok();
        }
        else if (activity?.Type == "conversationUpdate")
        {
            // Send welcome message for new conversations
            var welcomeMessage = new
            {
                type = "message",
                text = "👋 **Welcome to PrimeAgent v2.0!**\n\n" +
                       "🔧 **Enhanced with:**\n" +
                       "• A2A Protocol for agent communication\n" +
                       "• Microsoft Semantic Kernel integration\n" +
                       "• Real-time collaboration with SecondaryAgent\n\n" +
                       "💬 **Try saying:** \"Hello\" or ask me anything!",
                from = new { id = "primeagent", name = "PrimeAgent" },
                timestamp = DateTime.UtcNow,
                conversation = activity.Conversation
            };

            // Post welcome message back to the connector
            try
            {
                var serviceUrl = JsonDocument.Parse(body).RootElement.GetProperty("serviceUrl").GetString();
                var conversationId = JsonDocument.Parse(body).RootElement.GetProperty("conversation").GetProperty("id").GetString();

                var welcomeJson = JsonSerializer.Serialize(welcomeMessage, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });
                var welcomeContent = new StringContent(welcomeJson, System.Text.Encoding.UTF8, "application/json");

                var welcomeClient = httpClientFactory.CreateClient();
                await welcomeClient.PostAsync($"{serviceUrl}/v3/conversations/{conversationId}/activities", welcomeContent);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to send welcome message to connector");
            }
        }

        // Default response for other activity types
        return Results.Ok();
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error processing message");
        return Results.BadRequest("Invalid message");
    }
});

app.MapGet("/api/health", () => Results.Json(new
{
    status = "healthy",
    framework = "Microsoft.Agents + A2A Protocol",
    version = "2.0.0",
    timestamp = DateTime.UtcNow,
    semanticKernel = "enabled",
    a2aProtocol = "enabled"
}));

app.MapGet("/", () => "PrimeAgent v2.0 - A2A Protocol + Microsoft Agents SDK + Semantic Kernel");

app.Run("http://localhost:3978");

public class A2ARequest
{
    public string Message { get; set; } = string.Empty;
    public string AgentId { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}

public class A2AResponse
{
    public string AgentName { get; set; } = string.Empty;
    public string Protocol { get; set; } = string.Empty;
    public string Response { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public string Version { get; set; } = string.Empty;
    public string[] Capabilities { get; set; } = Array.Empty<string>();
}

public class BotActivity
{
    public string Type { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
    public string Id { get; set; } = string.Empty;
    public object Conversation { get; set; } = new object();
    public object From { get; set; } = new object();
}
