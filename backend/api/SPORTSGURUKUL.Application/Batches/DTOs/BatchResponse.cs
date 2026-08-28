namespace SPORTSGURUKUL.Application.Batches.DTOs;

public sealed class BatchResponse
{
    public Guid BatchId { get; set; }
    public Guid AcademyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? SportId { get; set; }
    public string? SportName { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public List<BatchScheduleSlotResponse> Slots { get; set; } = [];
    public List<BatchCoachResponse> Coaches { get; set; } = [];
    public List<BatchAthleteResponse> Athletes { get; set; } = [];
}

public sealed class BatchScheduleSlotResponse
{
    public Guid SlotId { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public string? Location { get; set; }
}

public sealed class BatchCoachResponse
{
    public Guid CoachId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? Specialization { get; set; }
    public DateTime AssignedAt { get; set; }

    public string FullName => $"{FirstName} {LastName}";
}

public sealed class BatchAthleteResponse
{
    public Guid AthleteId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PrimarySport { get; set; }
    public DateTime AssignedAt { get; set; }

    public string FullName => $"{FirstName} {LastName}";
}
