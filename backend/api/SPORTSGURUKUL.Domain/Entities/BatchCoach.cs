namespace SPORTSGURUKUL.Domain.Entities;

public class BatchCoach
{
    public Guid BatchId { get; set; }
    public Guid CoachId { get; set; }
    public DateTime AssignedAt { get; set; }

    public Batch Batch { get; set; } = null!;
    public Coach Coach { get; set; } = null!;
}
