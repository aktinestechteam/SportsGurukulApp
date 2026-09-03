using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Common;
using SPORTSGURUKUL.Application.Videos.DTOs;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Commands;

public sealed record EditCommentCommand(Guid CommentId, string Message)
    : IRequest<ApiResponse<VideoCommentResponse>>;

public sealed class EditCommentCommandValidator : AbstractValidator<EditCommentCommand>
{
    public EditCommentCommandValidator()
    {
        RuleFor(x => x.CommentId)
            .NotEmpty().WithMessage("Comment id is required.");

        RuleFor(x => x.Message)
            .NotEmpty().WithMessage("Comment message is required.")
            .MaximumLength(2000).WithMessage("Comment message must not exceed 2000 characters.");
    }
}

public sealed class EditCommentCommandHandler
    : IRequestHandler<EditCommentCommand, ApiResponse<VideoCommentResponse>>
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly IS3Service _s3Service;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<EditCommentCommandHandler> _logger;

    public EditCommentCommandHandler(
        IAthleteRepository athleteRepository,
        IVideoRepository videoRepository,
        IS3Service s3Service,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<EditCommentCommandHandler> logger)
    {
        _athleteRepository = athleteRepository;
        _videoRepository = videoRepository;
        _s3Service = s3Service;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<VideoCommentResponse>> Handle(
        EditCommentCommand command,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to edit a comment.");
        }

        var comment = await _videoRepository.GetCommentByIdAsync(command.CommentId, cancellationToken)
            ?? throw AppException.NotFound("Comment not found.");

        if (comment.IsDeleted)
        {
            throw AppException.NotFound("Comment not found.");
        }

        if (comment.AuthorUserId != userId)
        {
            throw AppException.Forbidden("You can only edit your own comments.");
        }

        if (!string.IsNullOrWhiteSpace(comment.VoiceNoteS3Key))
        {
            throw AppException.BadRequest("Voice note comments cannot be edited.");
        }

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken);

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            comment.Message = command.Message.Trim();
            comment.Touch();

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            var updated = await _videoRepository.GetCommentByIdAsync(comment.Id, cancellationToken);

            _logger.LogInformation(
                "Comment {CommentId} edited by user {UserId}",
                comment.Id,
                userId);

            return ApiResponse<VideoCommentResponse>.Ok(
                await VideoResponseMapper.ToCommentAsync(
                    updated!,
                    athlete is not null ? "Athlete" : "Coach",
                    userId,
                    _s3Service,
                    cancellationToken),
                "Comment updated successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}