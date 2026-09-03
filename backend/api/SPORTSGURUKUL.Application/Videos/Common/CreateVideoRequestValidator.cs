using FluentValidation;
using SPORTSGURUKUL.Application.Common.Constants;
using SPORTSGURUKUL.Application.Videos.DTOs;

namespace SPORTSGURUKUL.Application.Videos.Common;

public class CreateVideoRequestValidator : AbstractValidator<CreateVideoRequest>
{
    public CreateVideoRequestValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Video title is required.")
            .MaximumLength(200).WithMessage("Video title must not exceed 200 characters.");

        RuleFor(x => x.Message)
            .MaximumLength(1000).WithMessage("Video message must not exceed 1000 characters.");

        RuleFor(x => x.S3Key)
            .NotEmpty().WithMessage("S3 key is required.")
            .Must(key => key.StartsWith(VideoConstants.VideoPrefix + "/", StringComparison.OrdinalIgnoreCase))
            .WithMessage($"S3 key must start with \"{VideoConstants.VideoPrefix}/\"");

        RuleFor(x => x.FileSizeBytes)
            .GreaterThan(0).WithMessage("File size must be greater than zero.")
            .LessThan(VideoConstants.MaxVideoSizeBytes)
            .WithMessage($"Video file size must be under {VideoConstants.MaxVideoSizeBytes / (1024 * 1024)} MB.");

        RuleFor(x => x.DurationSeconds)
            .GreaterThan(0).WithMessage("Duration must be greater than zero.")
            .LessThan(VideoConstants.MaxVideoDurationSeconds)
            .WithMessage($"Video duration must be under {VideoConstants.MaxVideoDurationSeconds} seconds.")
            .When(x => x.DurationSeconds.HasValue);
    }
}