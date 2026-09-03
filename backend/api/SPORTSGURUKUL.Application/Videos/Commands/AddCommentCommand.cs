using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Common;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Videos.Commands;

public sealed record AddCommentCommand(Guid VideoId, AddCommentRequest Request)
    : IRequest<ApiResponse<VideoCommentResponse>>;

public sealed class AddCommentCommandValidator : AbstractValidator<AddCommentCommand>
{
    public AddCommentCommandValidator()
    {
        RuleFor(x => x.VideoId)
            .NotEmpty().WithMessage("Video id is required.");

        RuleFor(x => x.Request)
            .SetValidator(new AddCommentRequestValidator());
    }
}

public sealed class AddCommentCommandHandler
    : IRequestHandler<AddCommentCommand, ApiResponse<VideoCommentResponse>>
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly IS3Service _s3Service;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AddCommentCommandHandler> _logger;

    public AddCommentCommandHandler(
        IAthleteRepository athleteRepository,
        ICoachRepository coachRepository,
        IVideoRepository videoRepository,
        IS3Service s3Service,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<AddCommentCommandHandler> logger)
    {
        _athleteRepository = athleteRepository;
        _coachRepository = coachRepository;
        _videoRepository = videoRepository;
        _s3Service = s3Service;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<VideoCommentResponse>> Handle(
        AddCommentCommand command,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to add a comment.");
        }

        var video = await _videoRepository.GetByIdAsync(command.VideoId, cancellationToken)
            ?? throw AppException.NotFound("Video not found.");

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken);
        var coach = await _coachRepository.GetByUserIdAsync(userId, cancellationToken);

        var ownsVideo = athlete is not null && athlete.Id == video.AthleteId;
        var coachHasAccess = coach is not null
            && await _videoRepository.HasCoachAccessAsync(coach.Id, command.VideoId, cancellationToken);

        if (!ownsVideo && !coachHasAccess)
        {
            throw AppException.Forbidden("You do not have access to this video.");
        }

        var request = command.Request;

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            var now = DateTime.UtcNow;
            var comment = new VideoComment
            {
                Id = Guid.NewGuid(),
                VideoSubmissionId = command.VideoId,
                AuthorUserId = userId,
                Message = request.Message?.Trim(),
                VoiceNoteS3Key = request.VoiceNoteS3Key,
                VoiceNoteDurationSeconds = request.VoiceNoteDurationSeconds,
                IsDeleted = false,
                CreatedAt = now,
                UpdatedAt = now
            };

            await _videoRepository.AddCommentAsync(comment, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            var created = await _videoRepository.GetCommentByIdAsync(comment.Id, cancellationToken);

            _logger.LogInformation(
                "Comment {CommentId} added to video {VideoId} by user {UserId}",
                comment.Id,
                command.VideoId,
                userId);

            return ApiResponse<VideoCommentResponse>.Ok(
                await VideoResponseMapper.ToCommentAsync(
                    created!,
                    athlete is not null ? "Athlete" : "Coach",
                    userId,
                    _s3Service,
                    cancellationToken),
                "Comment added successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}