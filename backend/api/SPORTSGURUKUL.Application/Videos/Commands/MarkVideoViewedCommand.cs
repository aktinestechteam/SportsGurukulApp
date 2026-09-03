using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Videos.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Videos.Commands;

public sealed record MarkVideoViewedCommand(Guid VideoId)
    : IRequest<ApiResponse<object>>;

public sealed class MarkVideoViewedCommandValidator : AbstractValidator<MarkVideoViewedCommand>
{
    public MarkVideoViewedCommandValidator()
    {
        RuleFor(x => x.VideoId)
            .NotEmpty().WithMessage("Video id is required.");
    }
}

public sealed class MarkVideoViewedCommandHandler
    : IRequestHandler<MarkVideoViewedCommand, ApiResponse<object>>
{
    private readonly IVideoRepository _videoRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<MarkVideoViewedCommandHandler> _logger;

    public MarkVideoViewedCommandHandler(
        IVideoRepository videoRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<MarkVideoViewedCommandHandler> logger)
    {
        _videoRepository = videoRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(
        MarkVideoViewedCommand command,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to view a video.");
        }

        _ = await _videoRepository.GetByIdAsync(command.VideoId, cancellationToken)
            ?? throw AppException.NotFound("Video not found.");

        if (await _videoRepository.HasViewedAsync(userId, command.VideoId, cancellationToken))
        {
            return ApiResponse<object>.OkNoData("Video already marked as viewed.");
        }

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            await _videoRepository.AddViewAsync(new VideoView
            {
                Id = Guid.NewGuid(),
                VideoSubmissionId = command.VideoId,
                UserId = userId,
                ViewedAt = DateTime.UtcNow
            }, cancellationToken);

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            _logger.LogInformation(
                "Video {VideoId} marked as viewed by user {UserId}",
                command.VideoId,
                userId);

            return ApiResponse<object>.OkNoData("Video marked as viewed.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}