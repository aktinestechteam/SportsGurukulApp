using MediatR;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Queries;

public sealed record GetAdminCoachesOverviewQuery(Guid AcademyId)
    : IRequest<ApiResponse<List<CoachOverviewResponse>>>;

public sealed class GetAdminCoachesOverviewQueryHandler
    : IRequestHandler<GetAdminCoachesOverviewQuery, ApiResponse<List<CoachOverviewResponse>>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetAdminCoachesOverviewQueryHandler(
        IAcademyRepository academyRepository,
        ICoachRepository coachRepository,
        ICoachAthleteRepository coachAthleteRepository,
        IVideoRepository videoRepository,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _coachRepository = coachRepository;
        _coachAthleteRepository = coachAthleteRepository;
        _videoRepository = videoRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<CoachOverviewResponse>>> Handle(
        GetAdminCoachesOverviewQuery query,
        CancellationToken cancellationToken)
    {
        var adminUserId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || adminUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view the coach overview.");
        }

        _ = await _academyRepository.GetByIdForOwnerAsync(
            query.AcademyId,
            adminUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var coaches = await _coachRepository.GetByAcademyAsync(query.AcademyId, cancellationToken);

        var mappings = await _coachAthleteRepository.GetByAcademyAsync(
            query.AcademyId, cancellationToken);
        var athleteCounts = mappings
            .GroupBy(ca => ca.CoachId)
            .ToDictionary(g => g.Key, g => g.Count());

        var response = new List<CoachOverviewResponse>(coaches.Count);
        foreach (var association in coaches)
        {
            var coach = association.Coach;
            response.Add(new CoachOverviewResponse
            {
                CoachId = coach.Id,
                FirstName = coach.User.FirstName,
                LastName = coach.User.LastName,
                Sports = coach.Sports
                    .Select(cs => cs.Sport.Name)
                    .ToList(),
                AthleteCount = athleteCounts.TryGetValue(coach.Id, out var count) ? count : 0,
                TotalVideoCount = await _videoRepository.GetVideoCountForCoachAsync(
                    coach.Id, cancellationToken),
                UnreviewedVideoCount = await _videoRepository.GetUnviewedCountForCoachAsync(
                    coach.Id, cancellationToken)
            });
        }

        return ApiResponse<List<CoachOverviewResponse>>.Ok(
            response,
            "Coach overview retrieved successfully.");
    }
}