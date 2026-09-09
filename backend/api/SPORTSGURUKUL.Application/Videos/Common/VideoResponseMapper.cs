using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Videos.Common;

public static class VideoResponseMapper
{
    public static async Task<VideoSummaryResponse> ToSummaryAsync(
        VideoSubmission video,
        Guid viewerUserId,
        IS3Service s3Service,
        CancellationToken cancellationToken = default)
    {
        var isViewed = video.Views.Any(v => v.UserId == viewerUserId);

        return new VideoSummaryResponse
        {
            Id = video.Id,
            Title = video.Title,
            SportId = video.SportId,
            SportName = video.Sport?.Name,
            AthleteId = video.AthleteId,
            AthleteName = BuildFullName(video.Athlete.User.FirstName, video.Athlete.User.LastName),
            ThumbnailUrl = string.IsNullOrWhiteSpace(video.ThumbnailS3Key)
                ? null
                : await s3Service.GeneratePresignedDownloadUrlAsync(video.ThumbnailS3Key),
            DurationSeconds = video.DurationSeconds,
            CommentCount = video.Comments.Count(c => !c.IsDeleted),
            IsViewed = isViewed,
            IsNew = !isViewed,
            CreatedAt = video.CreatedAt
        };
    }

    public static async Task<VideoDetailResponse> ToDetailAsync(
        VideoSubmission video,
        Guid viewerUserId,
        IS3Service s3Service,
        CancellationToken cancellationToken = default)
    {
        var athleteUserId = video.Athlete.UserId;
        var isViewed = video.Views.Any(v => v.UserId == viewerUserId);

        var comments = new List<VideoCommentResponse>(video.Comments.Count);
        foreach (var comment in video.Comments.OrderBy(c => c.CreatedAt))
        {
            comments.Add(await ToCommentAsync(
                comment,
                comment.AuthorUserId == athleteUserId ? "Athlete" : "Coach",
                viewerUserId,
                s3Service,
                cancellationToken));
        }

        return new VideoDetailResponse
        {
            Id = video.Id,
            Title = video.Title,
            SportId = video.SportId,
            SportName = video.Sport?.Name,
            AthleteId = video.AthleteId,
            AthleteName = BuildFullName(video.Athlete.User.FirstName, video.Athlete.User.LastName),
            ThumbnailUrl = string.IsNullOrWhiteSpace(video.ThumbnailS3Key)
                ? null
                : await s3Service.GeneratePresignedDownloadUrlAsync(video.ThumbnailS3Key),
            Message = video.Message,
            VideoUrl = await s3Service.GeneratePresignedDownloadUrlAsync(video.S3Key),
            DurationSeconds = video.DurationSeconds,
            CommentCount = video.Comments.Count(c => !c.IsDeleted),
            IsViewed = isViewed,
            IsNew = !isViewed,
            CreatedAt = video.CreatedAt,
            Comments = comments
        };
    }

    public static async Task<VideoCommentResponse> ToCommentAsync(
        VideoComment comment,
        string authorRole,
        Guid viewerUserId,
        IS3Service s3Service,
        CancellationToken cancellationToken = default)
    {
        return new VideoCommentResponse
        {
            Id = comment.Id,
            AuthorName = BuildFullName(comment.Author.FirstName, comment.Author.LastName),
            AuthorRole = authorRole,
            Message = comment.Message,
            VoiceNoteUrl = string.IsNullOrWhiteSpace(comment.VoiceNoteS3Key)
                ? null
                : await s3Service.GeneratePresignedDownloadUrlAsync(comment.VoiceNoteS3Key),
            VoiceNoteDurationSeconds = comment.VoiceNoteDurationSeconds,
            IsDeleted = comment.IsDeleted,
            CreatedAt = comment.CreatedAt,
            IsOwnComment = comment.AuthorUserId == viewerUserId
        };
    }

    private static string BuildFullName(string firstName, string lastName)
        => string.IsNullOrWhiteSpace(lastName) ? firstName : $"{firstName} {lastName}".Trim();
}