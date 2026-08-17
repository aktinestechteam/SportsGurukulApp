using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Domain.Entities;

public class AcademyCoach
{
    public Guid AcademyId { get; set; }
    public Guid CoachId { get; set; }
    public Guid? BranchId { get; set; }
    public Guid? AssignedBy { get; set; }
    public CoachStatus Status { get; set; } = CoachStatus.Invited;
    public bool IsActive { get; set; } = true;
    public DateTime AssignedAt { get; set; }

    public Academy Academy { get; set; } = null!;
    public Coach Coach { get; set; } = null!;
    public AcademyBranch? Branch { get; set; }
}
