namespace SPORTSGURUKUL.Domain.Entities;

public class VideoView
{
    public Guid Id { get; set; }
    public Guid VideoSubmissionId { get; set; }
    public Guid UserId { get; set; }
    public DateTime ViewedAt { get; set; }

    public VideoSubmission VideoSubmission { get; set; } = null!;
    public User User { get; set; } = null!;
}
