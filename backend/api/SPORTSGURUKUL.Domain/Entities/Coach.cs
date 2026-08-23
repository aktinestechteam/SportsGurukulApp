namespace SPORTSGURUKUL.Domain.Entities;

public class Coach
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<AcademyCoach> AcademyAssociations { get; set; } = [];
    public ICollection<CoachSport> Sports { get; set; } = [];
    public ICollection<CoachAthlete> AthleteMappings { get; set; } = [];

    public void Touch() => UpdatedAt = DateTime.UtcNow;
}
