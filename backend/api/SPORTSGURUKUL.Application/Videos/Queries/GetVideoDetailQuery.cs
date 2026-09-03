using MediatR;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Common;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Queries;

public sealed record GetVideoDetailQuery(Guid VideoId)
    : IRequest<ApiResponse<VideoDetailResponse>>;

public sealed class GetVideoDetailQueryHandler
    : IRequestHandler<GetVideoDetailQuery, ApiResponse<VideoDetailResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly IS3Service _s3Service;
    private readonly ICurrentUserService _currentUserService;

    public GetVideoDetailQueryHandler(
        IAcademyRepository academyRepository,
        IAthleteRepository athleteRepository,
        ICoachRepository coachRepository,
        IVideoRepository videoRepository,
        IS3Service s3Service,
        ICurrentUserService currentUserService)
    {
        _academyRepository = academyRepository;
        _athleteRepository = athleteRepository;
        _coachRepository = coachRepository;
        _videoRepository = videoRepository;
        _s3Service = s3Service;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<VideoDetailResponse>> Handle(
        GetVideoDetailQuery query,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view a video.");
        }

        var video = await _videoRepository.GetByIdAsync(query.VideoId, cancellationToken)
            ?? throw AppException.NotFound("Video not found.");

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken);
        var coach = await _coachRepository.GetByUserIdAsync(userId, cancellationToken);

        var ownsVideo = athlete is not null && athlete.Id == video.AthleteId;
        var coachHasAccess = coach is not null
            && await _videoRepository.HasCoachAccessAsync(coach.Id, query.VideoId, cancellationToken);

        var academies = await _academyRepository.GetByOwnerAsync(userId, cancellationToken);
        var adminOwnsAcademy = academies.Any(a =>
            a.AthleteAssociations.Any(aa => aa.AthleteId == video.AthleteId));

        if (!ownsVideo && !coachHasAccess && !adminOwnsAcademy)
        {
            throw AppException.Forbidden("You do not have access to this video.");
        }

        return ApiResponse<VideoDetailResponse>.Ok(
            await VideoResponseMapper.ToDetailAsync(
                video, userId, _s3Service, cancellationToken),
            "Video retrieved successfully.");
    }
}