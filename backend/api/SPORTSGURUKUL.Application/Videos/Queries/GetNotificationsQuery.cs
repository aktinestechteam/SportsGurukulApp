using MediatR;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Queries;

public sealed record GetNotificationsQuery
    : IRequest<ApiResponse<List<NotificationResponse>>>;

public sealed class GetNotificationsQueryHandler
    : IRequestHandler<GetNotificationsQuery, ApiResponse<List<NotificationResponse>>>
{
    private const int MaxItems = 50;
    private const int FetchBatch = 50;

    private readonly ICoachRepository _coachRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetNotificationsQueryHandler(
        ICoachRepository coachRepository,
        IAthleteRepository athleteRepository,
        IVideoRepository videoRepository,
        ICurrentUserService currentUserService)
    {
        _coachRepository = coachRepository;
        _athleteRepository = athleteRepository;
        _videoRepository = videoRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<List<NotificationResponse>>> Handle(
        GetNotificationsQuery query,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view notifications.");
        }

        var since = DateTime.UtcNow.AddDays(-7);

        var coach = await _coachRepository.GetByUserIdAsync(userId, cancellationToken);
        if (coach is not null)
        {
            var videosTask = _videoRepository.GetRecentAssignedVideosForCoachAsync(
                coach.Id, since, FetchBatch, cancellationToken);
            var commentsTask = _videoRepository.GetRecentCommentsForCoachAsync(
                coach.Id, userId, since, FetchBatch, cancellationToken);

            await Task.WhenAll(videosTask, commentsTask);

            var notifications = new List<NotificationResponse>(MaxItems);

            foreach (var video in await videosTask)
            {
                notifications.Add(new NotificationResponse
                {
                    Type = "new_video",
                    VideoId = video.Id.ToString(),
                    VideoTitle = video.Title,
                    ActorName = BuildFullName(video.Athlete.User.FirstName, video.Athlete.User.LastName),
                    AthleteId = video.AthleteId.ToString(),
                    CreatedAt = video.CreatedAt
                });
            }

            foreach (var comment in await commentsTask)
            {
                notifications.Add(new NotificationResponse
                {
                    Type = "new_comment",
                    VideoId = comment.VideoSubmissionId.ToString(),
                    VideoTitle = comment.VideoSubmission.Title,
                    ActorName = BuildFullName(comment.Author.FirstName, comment.Author.LastName),
                    AthleteId = comment.VideoSubmission.AthleteId.ToString(),
                    CreatedAt = comment.CreatedAt
                });
            }

            return ApiResponse<List<NotificationResponse>>.Ok(
                notifications.OrderByDescending(n => n.CreatedAt).Take(MaxItems).ToList(),
                "Notifications retrieved successfully.");
        }

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken);
        if (athlete is not null)
        {
            var comments = await _videoRepository.GetRecentCommentsForAthleteAsync(
                athlete.Id, userId, since, FetchBatch, cancellationToken);

            var notifications = comments.Select(comment => new NotificationResponse
            {
                Type = "new_comment",
                VideoId = comment.VideoSubmissionId.ToString(),
                VideoTitle = comment.VideoSubmission.Title,
                ActorName = BuildFullName(comment.Author.FirstName, comment.Author.LastName),
                AthleteId = athlete.Id.ToString(),
                CreatedAt = comment.CreatedAt
            });

            return ApiResponse<List<NotificationResponse>>.Ok(
                notifications.OrderByDescending(n => n.CreatedAt).Take(MaxItems).ToList(),
                "Notifications retrieved successfully.");
        }

        return ApiResponse<List<NotificationResponse>>.Ok(
            [],
            "No notifications.");
    }

    private static string BuildFullName(string firstName, string lastName)
        => string.IsNullOrWhiteSpace(lastName) ? firstName : $"{firstName} {lastName}".Trim();
}
