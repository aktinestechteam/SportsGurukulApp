using MediatR;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Common;
using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Coaches.Queries;

public sealed record GetAcademyCoachesQuery(Guid AcademyId) : IRequest<ApiResponse<List<CoachResponse>>>;

public sealed class GetAcademyCoachesQueryHandler
    : IRequestHandler<GetAcademyCoachesQuery, ApiResponse<List<CoachResponse>>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetAcademyCoachesQueryHandler(
        IAcademyRepository academyRepository,
        ICoachRepository coachRepository,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _coachRepository = coachRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<CoachResponse>>> Handle(
        GetAcademyCoachesQuery query,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view coaches.");
        }

        _ = await _academyRepository.GetByIdForOwnerAsync(
            query.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var associations = await _coachRepository.GetByAcademyAsync(query.AcademyId, cancellationToken);

        return ApiResponse<List<CoachResponse>>.Ok(
            associations.Select(CoachResponseMapper.Map).ToList(),
            "Coaches retrieved successfully.");
    }
}
