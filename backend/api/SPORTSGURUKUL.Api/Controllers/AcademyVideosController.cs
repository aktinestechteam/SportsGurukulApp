using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SPORTSGURUKUL.Application.Videos.Queries;

namespace SPORTSGURUKUL.Api.Controllers;

[ApiController]
[Route("api/academies/{academyId:guid}/videos")]
[Authorize]
public class AcademyVideosController : ControllerBase
{
    private readonly IMediator _mediator;

    public AcademyVideosController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("coaches")]
    public async Task<IActionResult> GetCoachesOverview(
        Guid academyId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new GetAdminCoachesOverviewQuery(academyId),
            cancellationToken);
        return Ok(result);
    }

    [HttpGet("coaches/{coachId:guid}")]
    public async Task<IActionResult> GetCoachVideoFeed(
        Guid academyId,
        Guid coachId,
        [FromQuery] Guid? sportId,
        [FromQuery] Guid? athleteId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new GetAdminCoachVideoFeedQuery(coachId, sportId, athleteId),
            cancellationToken);
        return Ok(result);
    }
}
