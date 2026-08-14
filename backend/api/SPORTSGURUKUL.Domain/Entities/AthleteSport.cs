namespace SPORTSGURUKUL.Domain.Entities;

public class AthleteSport
{
    public Guid AthleteId { get; set; }
    public Guid SportId { get; set; }
    public bool IsPrimary { get; set; }
    public DateTime CreatedAt { get; set; }

    public Athlete Athlete { get; set; } = null!;
    public AcademySport Sport { get; set; } = null!;
}
