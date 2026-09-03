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
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Videos.Commands;

public sealed record CreateVideoCommand(CreateVideoRequest Request)
    : IRequest<ApiResponse<VideoDetailResponse>>;

public sealed class CreateVideoCommandValidator : AbstractValidator<CreateVideoCommand>
{
    public CreateVideoCommandValidator()
    {
        RuleFor(x => x.Request)
            .SetValidator(new CreateVideoRequestValidator());
    }
}

public sealed class CreateVideoCommandHandler
    : IRequestHandler<CreateVideoCommand, ApiResponse<VideoDetailResponse>>
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IVideoRepository _videoRepository;
    private readonly IS3Service _s3Service;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CreateVideoCommandHandler> _logger;

    public CreateVideoCommandHandler(
        IAthleteRepository athleteRepository,
        IVideoRepository videoRepository,
        IS3Service s3Service,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<CreateVideoCommandHandler> logger)
    {
        _athleteRepository = athleteRepository;
        _videoRepository = videoRepository;
        _s3Service = s3Service;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<VideoDetailResponse>> Handle(
        CreateVideoCommand command,
        CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || userId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to submit a video.");
        }

        var athlete = await _athleteRepository.GetByUserIdAsync(userId, cancellationToken)
            ?? throw AppException.Forbidden("Only athletes can submit videos.");

        var request = command.Request;

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            var now = DateTime.UtcNow;
            var video = new VideoSubmission
            {
                Id = Guid.NewGuid(),
                AthleteId = athlete.Id,
                SportId = request.SportId,
                Title = request.Title.Trim(),
                Message = request.Message?.Trim(),
                S3Key = request.S3Key,
                ThumbnailS3Key = request.ThumbnailS3Key,
                DurationSeconds = request.DurationSeconds.GetValueOrDefault(),
                FileSizeBytes = request.FileSizeBytes,
                Status = VideoStatus.Ready,
                IsDeleted = false,
                CreatedAt = now,
                UpdatedAt = now
            };

            await _videoRepository.AddAsync(video, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            var created = await _videoRepository.GetByIdAsync(video.Id, cancellationToken);

            _logger.LogInformation(
                "Video {VideoId} ({Title}) submitted by athlete {AthleteId}",
                video.Id,
                video.Title,
                athlete.Id);

            return ApiResponse<VideoDetailResponse>.Ok(
                await VideoResponseMapper.ToDetailAsync(created!, userId, _s3Service, cancellationToken),
                "Video submitted successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}