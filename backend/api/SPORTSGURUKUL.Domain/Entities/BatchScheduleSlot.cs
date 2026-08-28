namespace SPORTSGURUKUL.Domain.Entities;

public class BatchScheduleSlot
{
    public Guid Id { get; set; }
    public Guid BatchId { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public string? Location { get; set; }
    public DateTime CreatedAt { get; set; }

    public Batch Batch { get; set; } = null!;
}
