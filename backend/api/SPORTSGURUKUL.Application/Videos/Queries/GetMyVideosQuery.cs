using MediatR;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Common;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Queries;

public sealed record GetMyVideosQuery
    : IRequest<ApiResponse<List<VideoSummaryResponse>>>;

public sealed class GetMyVideosQueryHandler
    : IRequestHandler<GetMyVideosQuery, ApiResponse<List<VideoSummaryResponse>>>
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly IS3Service _s3Service;
    private readonly ICurrentUserService _currentUserService;

    public GetMyVideosQueryHandler(
        IAthleteRepository athleteRepository,
        IVideoRepository videoRepository,
        IS3Service s3Service,
        ICurrentUserService currentUserService)
    {
        _athleteRepository = athleteRepository;
        _videoRepository = videoRepository;
        _s3Service = s3Service;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<VideoSummaryResponse>>> Handle(
        GetMyVideosQuery query,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view your videos.");
        }

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken)
            ?? throw AppException.NotFound("Athlete profile not found.");

        var videos = await _videoRepository.GetByAthleteIdAsync(athlete.Id, cancellationToken);

        var response = new List<VideoSummaryResponse>(videos.Count);
        foreach (var video in videos)
        {
            response.Add(await VideoResponseMapper.ToSummaryAsync(
                video, userId, _s3Service, cancellationToken));
        }

        return ApiResponse<List<VideoSummaryResponse>>.Ok(
            response,
            "Videos retrieved successfully.");
    }
}