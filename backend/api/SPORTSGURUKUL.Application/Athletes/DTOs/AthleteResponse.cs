using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Athletes.DTOs;

public sealed class AthleteResponse
{
    public Guid AthleteId { get; set; }
    public Guid UserId { get; set; }
    public string PublicUserId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public AthleteGender Gender { get; set; }
    public string? AgeGroup { get; set; }
    public string? Address { get; set; }
    public string? EmergencyContact { get; set; }
    public Guid AcademyId { get; set; }
    public string AcademyName { get; set; } = string.Empty;
    public Guid? BranchId { get; set; }
    public string? BranchName { get; set; }
    public AthleteStatus Status { get; set; }
    public AthleteSportResponse PrimarySport { get; set; } = null!;
    public AthleteSportResponse? SecondarySport { get; set; }
    public List<MappedCoachResponse> MappedCoaches { get; set; } = [];
    public DateTime CreatedAt { get; set; }
}

public sealed class AthleteSportResponse
{
    public Guid SportId { get; set; }
    public string Name { get; set; } = string.Empty;
}

public sealed class MappedCoachResponse
{
    public Guid CoachId { get; set; }
    public string Name { get; set; } = string.Empty;
}
