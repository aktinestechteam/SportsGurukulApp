namespace SPORTSGURUKUL.Application.Academies.DTOs;

public sealed class AcademyResponse
{
    public Guid AcademyId { get; set; }
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
    public int CoachCount { get; set; }
    public int AthleteCount { get; set; }

    public List<AcademyBranchResponse> Branches { get; set; } = [];
    public List<AcademySportResponse> Sports { get; set; } = [];
    public List<AcademyFacilityResponse> Facilities { get; set; } = [];
    public List<AcademyMembershipResponse> Memberships { get; set; } = [];
    public List<AcademyWorkingHourResponse> WorkingHours { get; set; } = [];
}

public sealed class AcademyBranchResponse
{
    public Guid BranchId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string? PostalCode { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public bool IsMain { get; set; }
}

public sealed class AcademySportResponse
{
    public Guid SportId { get; set; }
    public string Name { get; set; } = string.Empty;
}

public sealed class AcademyFacilityResponse
{
    public Guid FacilityId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Type { get; set; }
    public int? Capacity { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

public sealed class AcademyMembershipResponse
{
    public Guid MembershipId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DurationDays { get; set; }
    public decimal Price { get; set; }
    public bool IsActive { get; set; }
}

public sealed class AcademyWorkingHourResponse
{
    public Guid WorkingHourId { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeOnly? OpenTime { get; set; }
    public TimeOnly? CloseTime { get; set; }
    public bool IsClosed { get; set; }
}
