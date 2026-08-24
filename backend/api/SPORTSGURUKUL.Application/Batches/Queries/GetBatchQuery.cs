using MediatR;
using SPORTSGURUKUL.Application.Batches.Common;
using SPORTSGURUKUL.Application.Batches.DTOs;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Batches.Queries;

public sealed record GetBatchQuery(Guid AcademyId, Guid BatchId)
    : IRequest<ApiResponse<BatchResponse>>;

public sealed class GetBatchQueryHandler
    : IRequestHandler<GetBatchQuery, ApiResponse<BatchResponse>>
{
    private readonly IBatchRepository _batchRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetBatchQueryHandler(
        IBatchRepository batchRepository,
        ICurrentUserService currentUserService)
    {
        _batchRepository = batchRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<BatchResponse>> Handle(
        GetBatchQuery query,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view a batch.");
        }

        var batch = await _batchRepository.GetByIdForOwnerAsync(
                query.BatchId,
                ownerUserId,
                cancellationToken)
            ?? throw AppException.NotFound("Batch not found.");

        if (batch.AcademyId != query.AcademyId)
        {
            throw AppException.NotFound("Batch not found in this academy.");
        }

        return ApiResponse<BatchResponse>.Ok(
            BatchResponseMapper.Map(batch),
            "Batch retrieved successfully.");
    }
}
