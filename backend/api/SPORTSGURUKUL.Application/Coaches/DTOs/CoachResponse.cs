using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Coaches.DTOs;

public sealed class CoachResponse
{
    public Guid CoachId { get; set; }
    public Guid UserId { get; set; }
    public string PublicUserId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public Guid AcademyId { get; set; }
    public string AcademyName { get; set; } = string.Empty;
    public Guid? BranchId { get; set; }
    public string? BranchName { get; set; }
    public CoachStatus Status { get; set; }
    public List<CoachSportResponse> Sports { get; set; } = [];
    public List<MappedAthleteResponse> MappedAthletes { get; set; } = [];
    public DateTime CreatedAt { get; set; }
}

public sealed class CoachSportResponse
{
    public Guid SportId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Specialization { get; set; }
}

public sealed class MappedAthleteResponse
{
    public Guid AthleteId { get; set; }
    public string Name { get; set; } = string.Empty;
}
