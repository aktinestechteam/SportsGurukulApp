namespace SPORTSGURUKUL.Application.Common.Constants;

public static class VideoConstants
{
    public const long MaxVideoSizeBytes = 100 * 1024 * 1024;   // 100MB
    public const int MaxVideoDurationSeconds = 180;              // 3 minutes
    public const long MaxVoiceNoteSizeBytes = 5 * 1024 * 1024; // 5MB
    public const int MaxVoiceNoteDurationSeconds = 120;          // 2 minutes
    public const long MaxThumbnailSizeBytes = 2 * 1024 * 1024; // 2MB

    // S3 key prefixes
    public const string VideoPrefix = "videos";
    public const string VoiceNotePrefix = "voice-notes";
    public const string ThumbnailPrefix = "thumbnails";
}