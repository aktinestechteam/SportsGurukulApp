using Microsoft.AspNetCore.SignalR;
using SPORTSGURUKUL.Api.Hubs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.DTOs;

namespace SPORTSGURUKUL.Api.Services;

/// <summary>
/// Sends real-time video events to connected SignalR clients. Comment events go
/// to the group of watchers for a video; new-video/deleted/coach-removed events
/// go to the specific coach user connections that should be notified.
/// </summary>
public class VideoHubService : IVideoHubService
{
    private readonly IHubContext<VideoHub> _hubContext;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly ICoachRepository _coachRepository;

    public VideoHubService(
        IHubContext<VideoHub> hubContext,
        IAthleteRepository athleteRepository,
        ICoachAthleteRepository coachAthleteRepository,
        ICoachRepository coachRepository)
    {
        _hubContext = hubContext;
        _athleteRepository = athleteRepository;
        _coachAthleteRepository = coachAthleteRepository;
        _coachRepository = coachRepository;
    }

    public Task PushNewCommentAsync(Guid videoId, VideoCommentResponse comment)
        => _hubContext.Clients
            .Group(VideoHub.GroupName(videoId))
            .SendAsync("NewComment", videoId, comment);

    public Task PushCommentUpdatedAsync(Guid videoId, VideoCommentResponse comment)
        => _hubContext.Clients
            .Group(VideoHub.GroupName(videoId))
            .SendAsync("CommentUpdated", videoId, comment);

    public Task PushCommentDeletedAsync(Guid videoId, Guid commentId)
        => _hubContext.Clients
            .Group(VideoHub.GroupName(videoId))
            .SendAsync("CommentDeleted", videoId, commentId);

    public async Task PushNewVideoAsync(Guid ownerUserId, VideoSummaryResponse video)
    {
        var coachUserIds = await ResolveAssignedCoachUserIdsAsync(ownerUserId);
        await PushToCoachUsersAsync("NewVideo", coachUserIds, video);
    }

    public async Task PushVideoDeletedAsync(Guid ownerUserId, Guid videoId)
    {
        var coachUserIds = await ResolveAssignedCoachUserIdsAsync(ownerUserId);
        await PushToCoachUsersAsync("VideoDeleted", coachUserIds, videoId);
    }

    public async Task PushCoachRemovedAsync(Guid coachId, Guid athleteId)
    {
        var coach = await _coachRepository.GetByIdAsync(coachId);
        if (coach is null)
        {
            return;
        }

        var connections = VideoHub.GetConnections(coach.UserId);
        if (connections.Count == 0)
        {
            return;
        }

        await _hubContext.Clients.Clients(connections).SendAsync("CoachRemoved", athleteId);
    }

    /// <summary>
    /// Resolves the user identities of every coach currently assigned to the
    /// athlete identified by the given owner user identity.
    /// </summary>
    private async Task<List<Guid>> ResolveAssignedCoachUserIdsAsync(Guid ownerUserId)
    {
        var athlete = await _athleteRepository.GetByUserIdAsync(ownerUserId);
        if (athlete is null)
        {
            return [];
        }

        var mappings = await _coachAthleteRepository.GetByAthleteAsync(athlete.Id);
        return mappings
            .Select(m => m.Coach.UserId)
            .Distinct()
            .ToList();
    }

    private async Task PushToCoachUsersAsync(string method, IReadOnlyList<Guid> coachUserIds, object payload)
    {
        var connectionIds = new List<string>();
        foreach (var coachUserId in coachUserIds)
        {
            connectionIds.AddRange(VideoHub.GetConnections(coachUserId));
        }

        if (connectionIds.Count == 0)
        {
            return;
        }

        await _hubContext.Clients.Clients(connectionIds).SendAsync(method, payload);
    }
}
