using MediatR;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Batches.Common;
using SPORTSGURUKUL.Application.Batches.DTOs;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Batches.Queries;

public sealed record GetAcademyBatchesQuery(Guid AcademyId)
    : IRequest<ApiResponse<List<BatchResponse>>>;

public sealed class GetAcademyBatchesQueryHandler
    : IRequestHandler<GetAcademyBatchesQuery, ApiResponse<List<BatchResponse>>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IBatchRepository _batchRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetAcademyBatchesQueryHandler(
        IAcademyRepository academyRepository,
        IBatchRepository batchRepository,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _batchRepository = batchRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<BatchResponse>>> Handle(
        GetAcademyBatchesQuery query,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view batches.");
        }

        _ = await _academyRepository.GetByIdForOwnerAsync(
                query.AcademyId,
                ownerUserId,
                cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var batches = await _batchRepository.GetByAcademyAsync(
            query.AcademyId, cancellationToken);

        return ApiResponse<List<BatchResponse>>.Ok(
            batches.Select(BatchResponseMapper.Map).ToList(),
            "Batches retrieved successfully.");
    }
}
