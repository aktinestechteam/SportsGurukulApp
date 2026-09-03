namespace SPORTSGURUKUL.Application.Videos.DTOs;

public sealed class VideoSummaryResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? SportName { get; set; }
    public Guid? AthleteId { get; set; }
    public string AthleteName { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public int DurationSeconds { get; set; }
    public int CommentCount { get; set; }
    public bool IsViewed { get; set; }
    public bool IsNew { get; set; }
    public DateTime CreatedAt { get; set; }
}

public sealed class VideoDetailResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? SportName { get; set; }
    public Guid? AthleteId { get; set; }
    public string AthleteName { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? Message { get; set; }
    public string VideoUrl { get; set; } = string.Empty;
    public int DurationSeconds { get; set; }
    public int CommentCount { get; set; }
    public bool IsViewed { get; set; }
    public bool IsNew { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<VideoCommentResponse> Comments { get; set; } = [];
}

public sealed class VideoCommentResponse
{
    public Guid Id { get; set; }
    public string AuthorName { get; set; } = string.Empty;
    public string? AuthorRole { get; set; }
    public string? Message { get; set; }
    public string? VoiceNoteUrl { get; set; }
    public int? VoiceNoteDurationSeconds { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsOwnComment { get; set; }
}

public sealed class CoachOverviewResponse
{
    public Guid CoachId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public List<string> Sports { get; set; } = [];
    public int AthleteCount { get; set; }
    public int TotalVideoCount { get; set; }
    public int UnreviewedVideoCount { get; set; }
}