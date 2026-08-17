namespace SPORTSGURUKUL.Application.Coaches.DTOs;

public sealed class CreateCoachRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;

    /// <summary>
    /// Existing academy branch the coach is assigned to. Required when the
    /// academy has at least one branch configured.
    /// </summary>
    public Guid? BranchId { get; set; }

    /// <summary>
    /// One or more sports configured for the academy that the coach teaches.
    /// </summary>
    public List<CoachSportAssignmentRequest> Sports { get; set; } = [];

    /// <summary>
    /// Athletes belonging to the academy that should be mapped to this coach.
    /// An athlete can be mapped to multiple coaches. Duplicates are ignored.
    /// </summary>
    public List<Guid> AthleteIds { get; set; } = [];
}

public sealed class CoachSportAssignmentRequest
{
    public Guid SportId { get; set; }
    public string? Specialization { get; set; }
}
