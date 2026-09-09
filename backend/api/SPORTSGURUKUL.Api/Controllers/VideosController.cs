using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Constants;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Commands;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Queries;

namespace SPORTSGURUKUL.Api.Controllers;

[ApiController]
[Route("api/videos")]
[Authorize]
public class VideosController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ICurrentUserService _currentUserService;
    private readonly IS3Service _s3Service;
    private readonly IVideoHubService _videoHubService;

    public VideosController(
        IMediator mediator,
        ICurrentUserService currentUserService,
        IS3Service s3Service,
        IVideoHubService videoHubService)
    {
        _mediator = mediator;
        _currentUserService = currentUserService;
        _s3Service = s3Service;
        _videoHubService = videoHubService;
    }

    [HttpPost("presigned-url")]
    public async Task<IActionResult> GeneratePresignedUrl(
        [FromBody] GeneratePresignedUrlRequest request,
        CancellationToken cancellationToken)
    {
        var isVideo = request.ContentType.StartsWith("video/", StringComparison.OrdinalIgnoreCase);
        var isAudio = request.ContentType.StartsWith("audio/", StringComparison.OrdinalIgnoreCase);
        var isImage = request.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase);

        // Only MP4 (H.264/AAC) videos are playable across Android, iOS and web.
        if (isVideo && !request.ContentType.Equals("video/mp4", StringComparison.OrdinalIgnoreCase))
        {
            throw AppException.BadRequest(
                "Only MP4 videos are supported. Please upload an MP4 (.mp4) file.");
        }

        if (isVideo && request.FileSizeBytes >= VideoConstants.MaxVideoSizeBytes)
        {
            throw AppException.BadRequest(
                $"Video must be under {VideoConstants.MaxVideoSizeBytes / (1024 * 1024)}MB.");
        }

        if (isAudio && request.FileSizeBytes >= VideoConstants.MaxVoiceNoteSizeBytes)
        {
            throw AppException.BadRequest(
                $"Voice note must be under {VideoConstants.MaxVoiceNoteSizeBytes / (1024 * 1024)}MB.");
        }

        if (isImage && request.FileSizeBytes >= VideoConstants.MaxThumbnailSizeBytes)
        {
            throw AppException.BadRequest(
                $"Image must be under {VideoConstants.MaxThumbnailSizeBytes / (1024 * 1024)}MB.");
        }

        var s3Key = isAudio
            ? BuildVoiceNoteS3Key()
            : isImage
                ? BuildThumbnailS3Key(request.FileName)
                : BuildVideoS3Key(request.FileName);

        var uploadUrl = await _s3Service.GeneratePresignedUploadUrlAsync(
            s3Key, request.ContentType, request.FileSizeBytes);

        return Ok(ApiResponse<PresignedUploadResponse>.Ok(
            new PresignedUploadResponse { UploadUrl = uploadUrl, S3Key = s3Key },
            "Presigned upload URL generated successfully."));
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateVideoRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new CreateVideoCommand(request), cancellationToken);
        if (result.Data is not null)
        {
            await _videoHubService.PushNewVideoAsync(
                _currentUserService.UserId,
                ToSummary(result.Data));
        }
        return Ok(result);
    }

    [HttpGet("mine")]
    public async Task<IActionResult> GetMyVideos(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetMyVideosQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpGet("feed")]
    public async Task<IActionResult> GetFeed(
        [FromQuery] Guid? sportId,
        [FromQuery] Guid? athleteId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new GetVideoFeedQuery(sportId, athleteId),
            cancellationToken);
        return Ok(result);
    }

    [HttpDelete("{videoId:guid}")]
    public async Task<IActionResult> Delete(
        Guid videoId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new DeleteVideoCommand(videoId), cancellationToken);
        await _videoHubService.PushVideoDeletedAsync(_currentUserService.UserId, videoId);
        return Ok(result);
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetUnviewedCountQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpGet("notifications")]
    public async Task<IActionResult> GetNotifications(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetNotificationsQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpGet("{videoId:guid}")]
    public async Task<IActionResult> GetById(
        Guid videoId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetVideoDetailQuery(videoId), cancellationToken);
        await _mediator.Send(new MarkVideoViewedCommand(videoId), cancellationToken);
        return Ok(result);
    }

    [HttpPost("{videoId:guid}/comments")]
    public async Task<IActionResult> AddComment(
        Guid videoId,
        [FromBody] AddCommentRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new AddCommentCommand(videoId, request), cancellationToken);
        if (result.Data is not null)
        {
            await _videoHubService.PushNewCommentAsync(videoId, result.Data);
        }
        return Ok(result);
    }

    [HttpPut("{videoId:guid}/comments/{commentId:guid}")]
    public async Task<IActionResult> EditComment(
        Guid videoId,
        Guid commentId,
        [FromBody] UpdateCommentRequest request,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(
            new EditCommentCommand(commentId, request.Message),
            cancellationToken);
        if (result.Data is not null)
        {
            await _videoHubService.PushCommentUpdatedAsync(videoId, result.Data);
        }
        return Ok(result);
    }

    [HttpDelete("{videoId:guid}/comments/{commentId:guid}")]
    public async Task<IActionResult> DeleteComment(
        Guid videoId,
        Guid commentId,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new DeleteCommentCommand(commentId), cancellationToken);
        await _videoHubService.PushCommentDeletedAsync(videoId, commentId);
        return Ok(result);
    }

    private static VideoSummaryResponse ToSummary(VideoDetailResponse detail)
        => new()
        {
            Id = detail.Id,
            Title = detail.Title,
            SportId = detail.SportId,
            SportName = detail.SportName,
            AthleteName = detail.AthleteName,
            ThumbnailUrl = detail.ThumbnailUrl,
            DurationSeconds = detail.DurationSeconds,
            CommentCount = detail.CommentCount,
            IsViewed = detail.IsViewed,
            IsNew = detail.IsNew,
            CreatedAt = detail.CreatedAt
        };

    private string BuildVideoS3Key(string fileName)
    {
        var extension = Path.GetExtension(fileName);
        return $"{VideoConstants.VideoPrefix}/{_currentUserService.UserId}/{Guid.NewGuid()}{extension}";
    }

    private static string BuildVoiceNoteS3Key()
        => $"{VideoConstants.VoiceNotePrefix}/{Guid.NewGuid()}/{Guid.NewGuid()}.m4a";

    private static string BuildThumbnailS3Key(string fileName)
    {
        var extension = Path.GetExtension(fileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".jpeg";
        }
        return $"{VideoConstants.ThumbnailPrefix}/{Guid.NewGuid()}{extension}";
    }
}

public sealed class GeneratePresignedUrlRequest
{
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
}

public sealed class UpdateCommentRequest
{
    public string Message { get; set; } = string.Empty;
}

public sealed class PresignedUploadResponse
{
    public string UploadUrl { get; set; } = string.Empty;
    public string S3Key { get; set; } = string.Empty;
}
