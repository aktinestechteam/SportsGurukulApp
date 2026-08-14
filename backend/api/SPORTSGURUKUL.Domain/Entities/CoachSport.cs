namespace SPORTSGURUKUL.Domain.Entities;

public class CoachSport
{
    public Guid CoachId { get; set; }
    public Guid SportId { get; set; }
    public string? Specialization { get; set; }
    public DateTime CreatedAt { get; set; }

    public Coach Coach { get; set; } = null!;
    public AcademySport Sport { get; set; } = null!;
}
