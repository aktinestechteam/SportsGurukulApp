using FluentValidation;
using SPORTSGURUKUL.Application.Common.Constants;
using SPORTSGURUKUL.Application.Videos.DTOs;

namespace SPORTSGURUKUL.Application.Videos.Common;

public class AddCommentRequestValidator : AbstractValidator<AddCommentRequest>
{
    public AddCommentRequestValidator()
    {
        RuleFor(x => x)
            .Must(x => !string.IsNullOrWhiteSpace(x.Message) || !string.IsNullOrWhiteSpace(x.VoiceNoteS3Key))
            .WithMessage("Either a message or a voice note is required.")
            .WithName("CommentContent");

        RuleFor(x => x.Message)
            .MaximumLength(2000).WithMessage("Comment message must not exceed 2000 characters.");

        When(x => !string.IsNullOrWhiteSpace(x.VoiceNoteS3Key), () =>
        {
            RuleFor(x => x.VoiceNoteS3Key)
                .Must(key => key!.StartsWith(VideoConstants.VoiceNotePrefix + "/", StringComparison.OrdinalIgnoreCase))
                .WithMessage($"Voice note S3 key must start with \"{VideoConstants.VoiceNotePrefix}/\"");

            RuleFor(x => x.VoiceNoteSizeBytes)
                .LessThan(VideoConstants.MaxVoiceNoteSizeBytes)
                .WithMessage($"Voice note file size must be under {VideoConstants.MaxVoiceNoteSizeBytes / (1024 * 1024)} MB.");

            RuleFor(x => x.VoiceNoteDurationSeconds)
                .LessThan(VideoConstants.MaxVoiceNoteDurationSeconds)
                .WithMessage($"Voice note duration must be under {VideoConstants.MaxVoiceNoteDurationSeconds} seconds.");
        });

        When(x => string.IsNullOrWhiteSpace(x.VoiceNoteS3Key), () =>
        {
            RuleFor(x => x.VoiceNoteSizeBytes)
                .Null().WithMessage("Voice note size requires a voice note.");

            RuleFor(x => x.VoiceNoteDurationSeconds)
                .Null().WithMessage("Voice note duration requires a voice note.");
        });
    }
}