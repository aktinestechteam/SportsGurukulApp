using MediatR;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Common;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Videos.Queries;

public sealed record GetAdminCoachVideoFeedQuery(
    Guid CoachId,
    Guid? SportId = null,
    Guid? AthleteId = null)
    : IRequest<ApiResponse<List<VideoSummaryResponse>>>;

public sealed class GetAdminCoachVideoFeedQueryHandler
    : IRequestHandler<GetAdminCoachVideoFeedQuery, ApiResponse<List<VideoSummaryResponse>>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly IS3Service _s3Service;
    private readonly ICurrentUserService _currentUserService;

    public GetAdminCoachVideoFeedQueryHandler(
        IAcademyRepository academyRepository,
        ICoachRepository coachRepository,
        IVideoRepository videoRepository,
        IS3Service s3Service,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _coachRepository = coachRepository;
        _videoRepository = videoRepository;
        _s3Service = s3Service;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<VideoSummaryResponse>>> Handle(
        GetAdminCoachVideoFeedQuery query,
        CancellationToken cancellationToken)
    {
        var adminUserId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || adminUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view the coach video feed.");
        }

        var academies = await _academyRepository.GetByOwnerAsync(adminUserId, cancellationToken);

        AcademyCoach? association = null;
        foreach (var academy in academies)
        {
            var coachesInAcademy = await _coachRepository.GetByAcademyAsync(
                academy.Id, cancellationToken);
            association = coachesInAcademy.FirstOrDefault(c => c.CoachId == query.CoachId);
            if (association is not null)
            {
                break;
            }
        }

        if (association is null)
        {
            throw AppException.NotFound("Coach not found in your academies.");
        }

        var videos = await _videoRepository.GetFeedForCoachAsync(
            query.CoachId,
            query.SportId,
            query.AthleteId,
            cancellationToken);

        var response = new List<VideoSummaryResponse>(videos.Count);
        foreach (var video in videos)
        {
            response.Add(await VideoResponseMapper.ToSummaryAsync(
                video, association.Coach.UserId, _s3Service, cancellationToken));
        }

        return ApiResponse<List<VideoSummaryResponse>>.Ok(
            response,
            "Coach video feed retrieved successfully.");
    }
}