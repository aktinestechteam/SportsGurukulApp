using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SPORTSGURUKUL.Application.Batches.Commands;
using SPORTSGURUKUL.Application.Batches.DTOs;
using SPORTSGURUKUL.Application.Batches.Queries;

namespace SPORTSGURUKUL.Api.Controllers;

[ApiController]
[Route("api/academies/{academyId:guid}/batches")]
[Authorize]
public class BatchesController : ControllerBase
{
    private readonly IMediator _mediator;

    public BatchesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        Guid academyId,
        [FromBody] BatchRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new CreateBatchCommand(academyId, request),
            cancellationToken);
        return Ok(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        Guid academyId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new GetAcademyBatchesQuery(academyId),
            cancellationToken);
        return Ok(result);
    }

    [HttpGet("{batchId:guid}")]
    public async Task<IActionResult> GetById(
        Guid academyId,
        Guid batchId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new GetBatchQuery(academyId, batchId),
            cancellationToken);
        return Ok(result);
    }

    [HttpPut("{batchId:guid}")]
    public async Task<IActionResult> Update(
        Guid academyId,
        Guid batchId,
        [FromBody] BatchRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new UpdateBatchCommand(academyId, batchId, request),
            cancellationToken);
        return Ok(result);
    }

    [HttpDelete("{batchId:guid}")]
    public async Task<IActionResult> Delete(
        Guid academyId,
        Guid batchId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new DeleteBatchCommand(academyId, batchId),
            cancellationToken);
        return Ok(result);
    }
}
