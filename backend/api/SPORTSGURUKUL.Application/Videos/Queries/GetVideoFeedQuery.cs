using MediatR;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Common;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Queries;

public sealed record GetVideoFeedQuery(
    Guid? SportId = null,
    Guid? AthleteId = null)
    : IRequest<ApiResponse<List<VideoSummaryResponse>>>;

public sealed class GetVideoFeedQueryHandler
    : IRequestHandler<GetVideoFeedQuery, ApiResponse<List<VideoSummaryResponse>>>
{
    private readonly ICoachRepository _coachRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly IS3Service _s3Service;
    private readonly ICurrentUserService _currentUserService;

    public GetVideoFeedQueryHandler(
        ICoachRepository coachRepository,
        IVideoRepository videoRepository,
        IS3Service s3Service,
        ICurrentUserService currentUserService)
    {
        _coachRepository = coachRepository;
        _videoRepository = videoRepository;
        _s3Service = s3Service;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<VideoSummaryResponse>>> Handle(
        GetVideoFeedQuery query,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view the video feed.");
        }

        var coach = await _coachRepository.GetByUserIdAsync(userId, cancellationToken)
            ?? throw AppException.NotFound("Coach profile not found.");

        var videos = await _videoRepository.GetFeedForCoachAsync(
            coach.Id,
            query.SportId,
            query.AthleteId,
            cancellationToken);

        var response = new List<VideoSummaryResponse>(videos.Count);
        foreach (var video in videos)
        {
            response.Add(await VideoResponseMapper.ToSummaryAsync(
                video, userId, _s3Service, cancellationToken));
        }

        return ApiResponse<List<VideoSummaryResponse>>.Ok(
            response,
            "Video feed retrieved successfully.");
    }
}