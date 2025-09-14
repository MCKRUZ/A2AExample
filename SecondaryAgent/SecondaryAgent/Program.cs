using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Connector.Authentication;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpClient();
builder.Services.AddControllers();

builder.Services.AddSingleton<BotFrameworkAuthentication, ConfigurationBotFrameworkAuthentication>();
builder.Services.AddSingleton<IBotFrameworkHttpAdapter>(sp => 
    new CloudAdapter(sp.GetRequiredService<BotFrameworkAuthentication>(), sp.GetService<ILogger<CloudAdapter>>()));
builder.Services.AddTransient<IBot, SecondaryAgentBot>();

var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();
app.UseWebSockets();
app.UseRouting();
app.UseAuthorization();
app.MapControllers();

app.MapGet("/", () => "SecondaryAgent is running and ready for Microsoft 365 Agent Playground!");

// Configure for Agent Playground alternate port
if (app.Environment.IsDevelopment())
{
    app.Run("http://localhost:3979");
}
else
{
    app.Run();
}
