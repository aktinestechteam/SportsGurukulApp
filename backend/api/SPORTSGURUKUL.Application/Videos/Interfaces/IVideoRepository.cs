using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Videos.Interfaces;

public interface IVideoRepository
{
    Task<VideoSubmission?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<List<VideoSubmission>> GetByAthleteIdAsync(Guid athleteId, CancellationToken cancellationToken = default);
    Task<List<VideoSubmission>> GetFeedForCoachAsync(Guid coachId, Guid? sportId, Guid? athleteId, CancellationToken cancellationToken = default);
    Task<List<VideoSubmission>> GetFeedForAdminAsync(Guid academyId, Guid? coachId, Guid? sportId, CancellationToken cancellationToken = default);
    Task<List<VideoComment>> GetCommentsAsync(Guid videoId, CancellationToken cancellationToken = default);
    Task<bool> HasCoachAccessAsync(Guid coachId, Guid videoId, CancellationToken cancellationToken = default);
    Task AddAsync(VideoSubmission video, CancellationToken cancellationToken = default);
    Task AddCommentAsync(VideoComment comment, CancellationToken cancellationToken = default);
    Task<VideoComment?> GetCommentByIdAsync(Guid commentId, CancellationToken cancellationToken = default);
    Task<int> SoftDeleteCommentsForVideoAsync(Guid videoId, CancellationToken cancellationToken = default);
    Task SoftDeleteAsync(Guid videoId, CancellationToken cancellationToken = default);
    Task<bool> HasViewedAsync(Guid userId, Guid videoId, CancellationToken cancellationToken = default);
    Task AddViewAsync(VideoView view, CancellationToken cancellationToken = default);
    Task<int> GetVideoCountForCoachAsync(Guid coachId, CancellationToken cancellationToken = default);
    Task<int> GetUnviewedCountForCoachAsync(Guid coachId, CancellationToken cancellationToken = default);
    Task<List<VideoSubmission>> GetRecentAssignedVideosForCoachAsync(
        Guid coachId, DateTime since, int limit, CancellationToken cancellationToken = default);
    Task<List<VideoComment>> GetRecentCommentsForCoachAsync(
        Guid coachId, Guid excludingUserId, DateTime since, int limit, CancellationToken cancellationToken = default);
    Task<List<VideoComment>> GetRecentCommentsForAthleteAsync(
        Guid athleteId, Guid excludingUserId, DateTime since, int limit, CancellationToken cancellationToken = default);
}