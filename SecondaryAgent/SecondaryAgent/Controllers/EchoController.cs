using Microsoft.AspNetCore.Mvc;

namespace SecondaryAgent.Controllers;

[Route("api/echo")]
[ApiController]
public class EchoController : ControllerBase
{
    private readonly ILogger<EchoController> _logger;
    private static int _messageCount = 0;

    public EchoController(ILogger<EchoController> logger)
    {
        _logger = logger;
    }

    [HttpPost]
    public IActionResult Echo([FromBody] EchoRequest request)
    {
        if (string.IsNullOrEmpty(request?.Message))
        {
            return BadRequest(new { error = "Message cannot be empty" });
        }

        _messageCount++;
        _logger.LogInformation($"SecondaryAgent received echo request #{_messageCount}: {request.Message}");

        // Simply echo back the message
        return Ok(new EchoResponse 
        { 
            Message = request.Message,
            MessageCount = _messageCount
        });
    }
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