using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Interfaces;

namespace SPORTSGURUKUL.Application.Videos.Commands;

public sealed record DeleteCommentCommand(Guid CommentId)
    : IRequest<ApiResponse<object>>;

public sealed class DeleteCommentCommandValidator : AbstractValidator<DeleteCommentCommand>
{
    public DeleteCommentCommandValidator()
    {
        RuleFor(x => x.CommentId)
            .NotEmpty().WithMessage("Comment id is required.");
    }
}

public sealed class DeleteCommentCommandHandler
    : IRequestHandler<DeleteCommentCommand, ApiResponse<object>>
{
    private readonly IVideoRepository _videoRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IS3Service _s3Service;
    private readonly ILogger<DeleteCommentCommandHandler> _logger;

    public DeleteCommentCommandHandler(
        IVideoRepository videoRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        IS3Service s3Service,
        ILogger<DeleteCommentCommandHandler> logger)
    {
        _videoRepository = videoRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _s3Service = s3Service;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(
        DeleteCommentCommand command,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to delete a comment.");
        }

        var comment = await _videoRepository.GetCommentByIdAsync(command.CommentId, cancellationToken)
            ?? throw AppException.NotFound("Comment not found.");

        if (comment.IsDeleted)
        {
            throw AppException.NotFound("Comment not found.");
        }

        if (comment.AuthorUserId != userId)
        {
            throw AppException.Forbidden("You can only delete your own comments.");
        }

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            comment.IsDeleted = true;
            comment.Touch();

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            if (!string.IsNullOrWhiteSpace(comment.VoiceNoteS3Key))
            {
                await _s3Service.DeleteObjectAsync(comment.VoiceNoteS3Key);
            }

            _logger.LogInformation(
                "Comment {CommentId} deleted by user {UserId}",
                comment.Id,
                userId);

            return ApiResponse<object>.OkNoData("Comment deleted successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}