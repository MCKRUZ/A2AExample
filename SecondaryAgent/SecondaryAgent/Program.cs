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
app.MapPost("/a2a", async (HttpContext context, ILogger<Program> logger) =>
{
    try
    {
        var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
        logger.LogInformation($"A2A request received: {body}");

        var request = JsonSerializer.Deserialize<A2ARequest>(body, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        // SecondaryAgent provides simple echo response
        var echoResponse = $"🔄 **SecondaryAgent Echo:**\n\n" +
                          $"You said: \"{request?.Message ?? body}\"";

        var response = new A2AResponse
        {
            AgentName = "SecondaryAgent",
            Protocol = "A2A",
            Response = echoResponse,
            Timestamp = DateTime.UtcNow,
            Version = "2.0.0",
            Capabilities = new[] { "echo", "a2a_communication", "simple_response" }
        };

        return Results.Json(response, new JsonSerializerOptions
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
    name = "SecondaryAgent",
    description = "Specialized analysis agent with A2A protocol support",
    version = "2.0.0",
    capabilities = new[] { "analysis", "a2a_communication", "contextual_insights", "specialized_processing" },
    protocol = "A2A",
    endpoints = new
    {
        a2a = "/a2a",
        echo = "/api/echo",
        messages = "/api/messages",
        health = "/api/health"
    }
}, new JsonSerializerOptions
{
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
}));

// Legacy echo endpoint for backward compatibility
app.MapPost("/api/echo", async (HttpContext context, ILogger<Program> logger) =>
{
    try
    {
        var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
        logger.LogInformation($"Echo request: {body}");

        var request = JsonSerializer.Deserialize<EchoRequest>(body, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        return Results.Json(new EchoResponse
        {
            Message = $"SecondaryAgent Echo: {request?.Message ?? body}",
            MessageCount = 1
        }, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error processing echo request");
        return Results.BadRequest("Invalid echo request");
    }
});

// Microsoft Agents SDK endpoint
app.MapPost("/api/messages", async (HttpContext context, ILogger<Program> logger) =>
{
    try
    {
        var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
        logger.LogInformation($"Message received: {body}");

        return Results.Json(new
        {
            type = "message",
            text = "SecondaryAgent with A2A protocol is ready for specialized analysis!",
            from = new { id = "secondaryagent", name = "SecondaryAgent" },
            timestamp = DateTime.UtcNow,
            serviceUrl = "http://localhost:3979",
            conversation = new { id = Guid.NewGuid().ToString() }
        });
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

app.MapGet("/", () => "SecondaryAgent v2.0 - A2A Protocol + Specialized Analysis");

app.Run("http://localhost:3979");

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

public class EchoRequest
{
    public string Message { get; set; } = string.Empty;
}

public class EchoResponse
{
    public string Message { get; set; } = string.Empty;
    public int MessageCount { get; set; }
}
