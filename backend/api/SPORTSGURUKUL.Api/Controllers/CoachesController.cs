using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SPORTSGURUKUL.Application.Coaches.Queries;

namespace SPORTSGURUKUL.Api.Controllers;

[ApiController]
[Route("api/coaches")]
[Authorize]
public class CoachesController : ControllerBase
{
    private readonly IMediator _mediator;

    public CoachesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetCoachProfileQuery(), cancellationToken);
        return Ok(result);
    }
}
