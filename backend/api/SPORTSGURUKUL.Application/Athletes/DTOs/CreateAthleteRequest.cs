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

    /// <summary>
    /// One or more sports configured for the academy. At least one sport is
    /// required. Duplicates are ignored.
    /// </summary>
    public List<Guid> SportIds { get; set; } = [];

    /// <summary>
    /// Coaches mapped to this athlete grouped per sport. Each entry pairs a
    /// sport with the coaches assigned to this athlete for that sport. A coach
    /// may appear under multiple sports. Duplicates are ignored.
    /// </summary>
    public List<AthleteCoachAssignment> CoachAssignments { get; set; } = [];
}

/// <summary>
/// Assigns a set of coaches to an athlete for a single sport.
/// </summary>
public sealed class AthleteCoachAssignment
{
    public Guid SportId { get; set; }
    public List<Guid> CoachIds { get; set; } = [];
}
