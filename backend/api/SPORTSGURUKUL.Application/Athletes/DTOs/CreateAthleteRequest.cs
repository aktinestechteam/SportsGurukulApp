using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Athletes.DTOs;

public sealed class CreateAthleteRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public AthleteGender? Gender { get; set; }
    public string? Address { get; set; }
    public string? EmergencyContact { get; set; }

    /// <summary>
    /// Existing academy branch the athlete is assigned to. Required when the
    /// academy has at least one branch configured.
    /// </summary>
    public Guid? BranchId { get; set; }

    /// <summary>Primary sport configured for the academy.</summary>
    public Guid PrimarySportId { get; set; }

    /// <summary>Optional secondary sport configured for the academy.</summary>
    public Guid? SecondarySportId { get; set; }

    /// <summary>
    /// Coaches belonging to the academy that should be mapped to this athlete.
    /// A coach can be mapped to multiple athletes. Duplicates are ignored.
    /// </summary>
    public List<Guid> CoachIds { get; set; } = [];
}
