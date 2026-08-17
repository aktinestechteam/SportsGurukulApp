using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Domain.Entities;

public class AcademyAthlete
{
    public Guid AcademyId { get; set; }
    public Guid AthleteId { get; set; }
    public Guid? BranchId { get; set; }
    public Guid? AssignedBy { get; set; }
    public AthleteStatus Status { get; set; } = AthleteStatus.Invited;
    public bool IsActive { get; set; } = true;
    public DateTime AssignedAt { get; set; }
    public DateTime? JoinedAt { get; set; }

    public Academy Academy { get; set; } = null!;
    public Athlete Athlete { get; set; } = null!;
    public AcademyBranch? Branch { get; set; }
}
