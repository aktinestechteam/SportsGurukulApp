using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Coaches.DTOs;

public sealed class CreateCoachResponse
{
    public Guid CoachId { get; set; }
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
}
