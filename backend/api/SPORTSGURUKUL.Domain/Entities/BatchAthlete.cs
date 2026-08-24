namespace SPORTSGURUKUL.Domain.Entities;

public class BatchAthlete
{
    public Guid BatchId { get; set; }
    public Guid AthleteId { get; set; }
    public DateTime AssignedAt { get; set; }

    public Batch Batch { get; set; } = null!;
    public Athlete Athlete { get; set; } = null!;
}
