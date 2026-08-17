namespace SPORTSGURUKUL.Domain.Entities;

public class Academy
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Profile { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string? PostalCode { get; set; }
    public string? LogoUrl { get; set; }
    public bool IsPublic { get; set; }
    public Guid OwnerUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User OwnerUser { get; set; } = null!;
    public ICollection<AcademyBranch> Branches { get; set; } = [];
    public ICollection<AcademySport> Sports { get; set; } = [];
    public ICollection<AcademyFacility> Facilities { get; set; } = [];
    public ICollection<AcademyMembership> Memberships { get; set; } = [];
    public ICollection<AcademyWorkingHour> WorkingHours { get; set; } = [];
    public ICollection<AcademyCoach> CoachAssociations { get; set; } = [];
    public ICollection<AcademyAthlete> AthleteAssociations { get; set; } = [];
    public ICollection<CoachAthlete> CoachAthleteMappings { get; set; } = [];

    public void Touch() => UpdatedAt = DateTime.UtcNow;
}
