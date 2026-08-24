namespace SPORTSGURUKUL.Domain.Entities;

public class Batch
{
    public Guid Id { get; set; }
    public Guid AcademyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? SportId { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public Academy Academy { get; set; } = null!;
    public AcademySport? Sport { get; set; }
    public ICollection<BatchScheduleSlot> Slots { get; set; } = [];
    public ICollection<BatchCoach> CoachAssociations { get; set; } = [];
    public ICollection<BatchAthlete> AthleteAssociations { get; set; } = [];

    public void Touch() => UpdatedAt = DateTime.UtcNow;
}
