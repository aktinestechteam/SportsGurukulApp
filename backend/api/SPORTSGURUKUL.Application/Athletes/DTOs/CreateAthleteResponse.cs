using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Athletes.DTOs;

public sealed class CreateAthleteResponse
{
    public Guid AthleteId { get; set; }
    public string PublicUserId { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public AthleteGender Gender { get; set; }
    public string? AgeGroup { get; set; }
    public Guid AcademyId { get; set; }
    public string AcademyName { get; set; } = string.Empty;
    public Guid? BranchId { get; set; }
    public string? BranchName { get; set; }
    public AthleteStatus Status { get; set; }
    public AthleteSportResponse PrimarySport { get; set; } = null!;
    public AthleteSportResponse? SecondarySport { get; set; }
    public List<MappedCoachResponse> MappedCoaches { get; set; } = [];
}
