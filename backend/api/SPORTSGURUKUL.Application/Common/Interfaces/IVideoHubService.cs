using SPORTSGURUKUL.Application.Videos.DTOs;

namespace SPORTSGURUKUL.Application.Common.Interfaces;

/// <summary>
/// Encapsulates real-time video events pushed to connected clients through
/// SignalR. The API-layer implementation wraps <c>IHubContext</c>.
/// </summary>
public interface IVideoHubService
{
    Task PushNewCommentAsync(Guid videoId, VideoCommentResponse comment);
    Task PushCommentUpdatedAsync(Guid videoId, VideoCommentResponse comment);
    Task PushCommentDeletedAsync(Guid videoId, Guid commentId);

    Task PushNewVideoAsync(Guid ownerUserId, VideoSummaryResponse video);
    Task PushVideoDeletedAsync(Guid ownerUserId, Guid videoId);
    Task PushCoachRemovedAsync(Guid coachId, Guid athleteId);
}
