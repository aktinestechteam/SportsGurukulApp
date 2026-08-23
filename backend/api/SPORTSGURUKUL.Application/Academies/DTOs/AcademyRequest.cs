namespace SPORTSGURUKUL.Application.Academies.DTOs;

public sealed class AcademyRequest
{
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

    public List<AcademyBranchRequest> Branches { get; set; } = [];
    public List<AcademySportRequest> Sports { get; set; } = [];
    public List<AcademyFacilityRequest> Facilities { get; set; } = [];
    public List<AcademyMembershipRequest> Memberships { get; set; } = [];
    public List<AcademyWorkingHourRequest> WorkingHours { get; set; } = [];
}

public sealed class AcademyBranchRequest
{
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

public sealed class AcademySportRequest
{
    public string Name { get; set; } = string.Empty;
}

public sealed class AcademyFacilityRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Type { get; set; }
    public int? Capacity { get; set; }
    public string? Description { get; set; }
}

public sealed class AcademyMembershipRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DurationDays { get; set; }
    public decimal Price { get; set; }
}

public sealed class AcademyWorkingHourRequest
{
    public DayOfWeek DayOfWeek { get; set; }
    public TimeOnly? OpenTime { get; set; }
    public TimeOnly? CloseTime { get; set; }
    public bool IsClosed { get; set; }
}
