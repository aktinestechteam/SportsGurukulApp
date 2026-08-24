namespace SPORTSGURUKUL.Application.Coaches.DTOs;

public sealed class CoachProfileResponse
{
    public string CoachId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public List<CoachProfileAcademy> Academies { get; set; } = [];
    public List<CoachProfileBatch> Batches { get; set; } = [];
    public List<CoachProfileAthlete> Athletes { get; set; } = [];
}

public sealed class CoachProfileAcademy
{
    public string AcademyId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public List<CoachProfileAcademySport> Sports { get; set; } = [];
}

public sealed class CoachProfileAcademySport
{
    public string Name { get; set; } = string.Empty;
    public string? Specialization { get; set; }
}

public sealed class CoachProfileBatch
{
    public string BatchId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string AcademyId { get; set; } = string.Empty;
    public string AcademyName { get; set; } = string.Empty;
    public string? SportName { get; set; }
    public bool AllowCoachBatchEdit { get; set; }
    public int AthletesCount { get; set; }
    public List<CoachProfileBatchSlot> Slots { get; set; } = [];
    public List<CoachProfileBatchPeer> Coaches { get; set; } = [];
    public List<CoachProfileBatchAthlete> Athletes { get; set; } = [];
}

public sealed class CoachProfileBatchAthlete
{
    public string AthleteId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? Sport { get; set; }
}

public sealed class CoachProfileBatchSlot
{
    public int DayOfWeek { get; set; }
    public string StartTime { get; set; } = string.Empty;
    public string EndTime { get; set; } = string.Empty;
    public string? Location { get; set; }
}

public sealed class CoachProfileBatchPeer
{
    public string CoachId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}

public sealed class CoachProfileAthlete
{
    public string AthleteId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? Sport { get; set; }
    public string? BatchName { get; set; }
    public string? Email { get; set; }
    public string? MobileNumber { get; set; }
}
