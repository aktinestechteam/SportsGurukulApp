using MediatR;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Common;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Athletes.Queries;

public sealed record GetAcademyAthletesQuery(Guid AcademyId) : IRequest<ApiResponse<List<AthleteResponse>>>;

public sealed class GetAcademyAthletesQueryHandler
    : IRequestHandler<GetAcademyAthletesQuery, ApiResponse<List<AthleteResponse>>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetAcademyAthletesQueryHandler(
        IAcademyRepository academyRepository,
        IAthleteRepository athleteRepository,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _athleteRepository = athleteRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<AthleteResponse>>> Handle(
        GetAcademyAthletesQuery query,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view athletes.");
        }

        _ = await _academyRepository.GetByIdForOwnerAsync(
            query.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var associations = await _athleteRepository.GetByAcademyAsync(query.AcademyId, cancellationToken);

        return ApiResponse<List<AthleteResponse>>.Ok(
            associations.Select(AthleteResponseMapper.Map).ToList(),
            "Athletes retrieved successfully.");
    }
}
