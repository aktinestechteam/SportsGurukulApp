using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SPORTSGURUKUL.Application.Athletes.Queries;

namespace SPORTSGURUKUL.Api.Controllers;

[ApiController]
[Route("api/athletes")]
[Authorize]
public class AthletesController : ControllerBase
{
    private readonly IMediator _mediator;

    public AthletesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAthleteProfileQuery(), cancellationToken);
        return Ok(result);
    }
}