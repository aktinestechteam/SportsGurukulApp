using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Domain.Entities;

public class VideoSubmission
{
    public Guid Id { get; set; }
    public Guid AthleteId { get; set; }
    public Guid? SportId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Message { get; set; }
    public string S3Key { get; set; } = string.Empty;
    public string? ThumbnailS3Key { get; set; }
    public int DurationSeconds { get; set; }
    public long FileSizeBytes { get; set; }
    public VideoStatus Status { get; set; } = VideoStatus.Processing;
    public bool IsDeleted { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public Athlete Athlete { get; set; } = null!;
    public AcademySport? Sport { get; set; }
    public ICollection<VideoComment> Comments { get; set; } = [];
    public ICollection<VideoView> Views { get; set; } = [];

    public void Touch() => UpdatedAt = DateTime.UtcNow;
}
