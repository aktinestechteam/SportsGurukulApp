namespace SPORTSGURUKUL.Application.Athletes.DTOs;

public sealed class AthleteProfileResponse
{
    public string AthleteId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public List<AthleteProfileSport> Sports { get; set; } = [];
    public List<AthleteProfileAcademy> Academies { get; set; } = [];
    public List<AthleteProfileBatch> Batches { get; set; } = [];
}

public sealed class AthleteProfileSport
{
    public Guid SportId { get; set; }
    public string Name { get; set; } = string.Empty;
}

public sealed class AthleteProfileAcademy
{
    public string AcademyId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
}

public sealed class AthleteProfileBatch
{
    public string BatchId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string AcademyId { get; set; } = string.Empty;
    public string AcademyName { get; set; } = string.Empty;
    public string? SportName { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public List<AthleteProfileBatchSlot> Slots { get; set; } = [];
    public List<AthleteProfileCoach> Coaches { get; set; } = [];
}

public sealed class AthleteProfileBatchSlot
{
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public string? Location { get; set; }
}

public sealed class AthleteProfileCoach
{
    public string CoachId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}