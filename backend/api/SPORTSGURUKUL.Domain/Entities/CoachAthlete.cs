namespace SPORTSGURUKUL.Domain.Entities;

/// <summary>
/// Many-to-many association linking a coach to an athlete within the scope of
/// an academy AND for a specific sport. A coach can map to many athletes and
/// an athlete can map to many coaches. Because the mapping is per sport, the
/// same athlete and coach can appear in multiple rows for different sports
/// (e.g. a coach who trains both Cricket and Football). The mapping is also
/// recorded per academy so both sides of the relationship stay synchronized
/// within the academy context they were created in.
/// </summary>
public class CoachAthlete
{
    public Guid CoachId { get; set; }
    public Guid AthleteId { get; set; }
    public Guid AcademyId { get; set; }
    public Guid SportId { get; set; }
    public Guid? AssignedBy { get; set; }
    public DateTime AssignedAt { get; set; }

    public Coach Coach { get; set; } = null!;
    public Athlete Athlete { get; set; } = null!;
    public Academy Academy { get; set; } = null!;
    public AcademySport Sport { get; set; } = null!;
}
