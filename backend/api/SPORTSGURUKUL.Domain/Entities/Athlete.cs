using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Domain.Entities;

public class Athlete
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateTime DateOfBirth { get; set; }
    public AthleteGender Gender { get; set; } = AthleteGender.Male;
    public string? Address { get; set; }
    public string? EmergencyContact { get; set; }
    public string? ProfilePhotoUrl { get; set; }
    public string? AgeGroup { get; set; }
    public DateTime? JoinedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<AcademyAthlete> AcademyAssociations { get; set; } = [];
    public ICollection<AthleteSport> Sports { get; set; } = [];
    public ICollection<CoachAthlete> CoachMappings { get; set; } = [];

    public void Touch() => UpdatedAt = DateTime.UtcNow;
}
