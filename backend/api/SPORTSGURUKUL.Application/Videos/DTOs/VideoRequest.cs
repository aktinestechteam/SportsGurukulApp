namespace SPORTSGURUKUL.Application.Videos.DTOs;

public sealed class CreateVideoRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Message { get; set; }
    public string S3Key { get; set; } = string.Empty;
    public string? ThumbnailS3Key { get; set; }
    public int? DurationSeconds { get; set; }
    public long FileSizeBytes { get; set; }
    public Guid? SportId { get; set; }
}

public sealed class AddCommentRequest
{
    public string? Message { get; set; }
    public string? VoiceNoteS3Key { get; set; }
    public int? VoiceNoteDurationSeconds { get; set; }
    public long? VoiceNoteSizeBytes { get; set; }
}