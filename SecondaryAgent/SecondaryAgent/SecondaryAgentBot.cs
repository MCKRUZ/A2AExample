using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;

public class SecondaryAgentBot : ActivityHandler
{
    private readonly ILogger<SecondaryAgentBot> _logger;
    private int _messageCount = 0;

    public SecondaryAgentBot(ILogger<SecondaryAgentBot> logger)
    {
        _logger = logger;
    }

    protected override async Task OnMembersAddedAsync(IList<ChannelAccount> membersAdded, ITurnContext<IConversationUpdateActivity> turnContext, CancellationToken cancellationToken)
    {
        foreach (var member in membersAdded)
        {
            if (member.Id != turnContext.Activity.Recipient.Id)
            {
                await turnContext.SendActivityAsync("Hello! I'm SecondaryAgent - I simply echo back whatever you send me.", 
                    cancellationToken: cancellationToken);
            }
        }
    }

    protected override async Task OnMessageActivityAsync(ITurnContext<IMessageActivity> turnContext, CancellationToken cancellationToken)
    {
        var userMessage = turnContext.Activity.Text?.Trim();
        
        if (string.IsNullOrEmpty(userMessage))
        {
            await turnContext.SendActivityAsync("[Empty message received]", cancellationToken: cancellationToken);
            return;
        }

        _messageCount++;
        _logger.LogInformation($"SecondaryAgent received message #{_messageCount}: {userMessage}");

        // Simply echo back exactly what was sent
        await turnContext.SendActivityAsync(userMessage, cancellationToken: cancellationToken);
    }
}