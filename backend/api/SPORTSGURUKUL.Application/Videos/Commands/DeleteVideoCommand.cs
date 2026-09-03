using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Commands;

public sealed record DeleteVideoCommand(Guid VideoId)
    : IRequest<ApiResponse<object>>;

public sealed class DeleteVideoCommandValidator : AbstractValidator<DeleteVideoCommand>
{
    public DeleteVideoCommandValidator()
    {
        RuleFor(x => x.VideoId)
            .NotEmpty().WithMessage("Video id is required.");
    }
}

public sealed class DeleteVideoCommandHandler
    : IRequestHandler<DeleteVideoCommand, ApiResponse<object>>
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IS3Service _s3Service;
    private readonly ILogger<DeleteVideoCommandHandler> _logger;

    public DeleteVideoCommandHandler(
        IAthleteRepository athleteRepository,
        IVideoRepository videoRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        IS3Service s3Service,
        ILogger<DeleteVideoCommandHandler> logger)
    {
        _athleteRepository = athleteRepository;
        _videoRepository = videoRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _s3Service = s3Service;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(
        DeleteVideoCommand command,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to delete a video.");
        }

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken)
            ?? throw AppException.Forbidden("Only athletes can delete videos.");

        var video = await _videoRepository.GetByIdAsync(command.VideoId, cancellationToken)
            ?? throw AppException.NotFound("Video not found.");

        if (video.AthleteId != athlete.Id)
        {
            throw AppException.Forbidden("You are not authorized to delete this video.");
        }

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            await _videoRepository.SoftDeleteAsync(command.VideoId, cancellationToken);

            var deletedComments =
                await _videoRepository.SoftDeleteCommentsForVideoAsync(command.VideoId, cancellationToken);

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            // Remove the media objects from S3 (video, thumbnail, and any
            // comment voice notes). Deletion failures are logged, not fatal.
            await _s3Service.DeleteObjectAsync(video.S3Key);
            if (!string.IsNullOrWhiteSpace(video.ThumbnailS3Key))
            {
                await _s3Service.DeleteObjectAsync(video.ThumbnailS3Key);
            }
            foreach (var comment in video.Comments)
            {
                if (!string.IsNullOrWhiteSpace(comment.VoiceNoteS3Key))
                {
                    await _s3Service.DeleteObjectAsync(comment.VoiceNoteS3Key);
                }
            }

            _logger.LogInformation(
                "Video {VideoId} deleted by athlete {AthleteId} ({DeletedComments} related comments removed)",
                command.VideoId,
                athlete.Id,
                deletedComments);

            return ApiResponse<object>.OkNoData("Video deleted successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}