using MediatR;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Common;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Athletes.Queries;

public sealed record GetAcademyAthletesQuery(Guid AcademyId) : IRequest<ApiResponse<List<AthleteResponse>>>;

public sealed class GetAcademyAthletesQueryHandler
    : IRequestHandler<GetAcademyAthletesQuery, ApiResponse<List<AthleteResponse>>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetAcademyAthletesQueryHandler(
        IAcademyRepository academyRepository,
        IAthleteRepository athleteRepository,
        ICoachAthleteRepository coachAthleteRepository,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _athleteRepository = athleteRepository;
        _coachAthleteRepository = coachAthleteRepository;
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
        var mappings = await _coachAthleteRepository.GetByAcademyAsync(query.AcademyId, cancellationToken);
        var mappingsByAthlete = mappings
            .GroupBy(ca => ca.AthleteId)
            .ToDictionary(g => g.Key, g => (IEnumerable<CoachAthlete>)g);

        return ApiResponse<List<AthleteResponse>>.Ok(
            associations
                .Select(a => AthleteResponseMapper.Map(
                    a,
                    mappingsByAthlete.TryGetValue(a.AthleteId, out var athleteMappings) ? athleteMappings : null))
                .ToList(),
            "Athletes retrieved successfully.");
    }
}
