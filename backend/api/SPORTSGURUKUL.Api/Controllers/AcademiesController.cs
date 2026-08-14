using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SPORTSGURUKUL.Application.Academies.Commands;
using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Application.Academies.Queries;
using SPORTSGURUKUL.Application.Coaches.Commands;
using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Application.Coaches.Queries;

namespace SPORTSGURUKUL.Api.Controllers;

[ApiController]
[Route("api/academies")]
[Authorize]
public class AcademiesController : ControllerBase
{
    private readonly IMediator _mediator;

    public AcademiesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] AcademyRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new CreateAcademyCommand(request), cancellationToken);
        return Ok(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAcademiesQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAcademyQuery(id), cancellationToken);
        return Ok(result);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(
        Guid id,
        [FromBody] AcademyRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new UpdateAcademyCommand(id, request), cancellationToken);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new DeleteAcademyCommand(id), cancellationToken);
        return Ok(result);
    }

    [HttpPost("{academyId:guid}/coaches")]
    public async Task<IActionResult> CreateCoach(
        Guid academyId,
        [FromBody] CreateCoachRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new CreateAcademyCoachCommand(academyId, request),
            cancellationToken);
        return Ok(result);
    }

    [HttpGet("{academyId:guid}/coaches")]
    public async Task<IActionResult> GetCoaches(Guid academyId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAcademyCoachesQuery(academyId), cancellationToken);
        return Ok(result);
    }

    [HttpPut("{academyId:guid}/coaches/{coachId:guid}")]
    public async Task<IActionResult> UpdateCoach(
        Guid academyId,
        Guid coachId,
        [FromBody] CreateCoachRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new UpdateAcademyCoachCommand(academyId, coachId, request),
            cancellationToken);
        return Ok(result);
    }

    [HttpDelete("{academyId:guid}/coaches/{coachId:guid}")]
    public async Task<IActionResult> DeleteCoach(
        Guid academyId,
        Guid coachId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new DeleteAcademyCoachCommand(academyId, coachId),
            cancellationToken);
        return Ok(result);
    }
}
