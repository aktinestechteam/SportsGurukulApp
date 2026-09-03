namespace SPORTSGURUKUL.Domain.Entities;

public class VideoComment
{
    public Guid Id { get; set; }
    public Guid VideoSubmissionId { get; set; }
    public Guid AuthorUserId { get; set; }
    public string? Message { get; set; }
    public string? VoiceNoteS3Key { get; set; }
    public int? VoiceNoteDurationSeconds { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public VideoSubmission VideoSubmission { get; set; } = null!;
    public User Author { get; set; } = null!;

    public void Touch() => UpdatedAt = DateTime.UtcNow;
}
