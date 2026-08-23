namespace SPORTSGURUKUL.Domain.Entities;

/// <summary>
/// Many-to-many association linking a coach to an athlete within the scope of
/// an academy. A coach can map to many athletes, an athlete can map to many
/// coaches, and the mapping is recorded per academy so both sides of the
/// relationship stay synchronized within the academy context they were
/// created in.
/// </summary>
public class CoachAthlete
{
    public Guid CoachId { get; set; }
    public Guid AthleteId { get; set; }
    public Guid AcademyId { get; set; }
    public Guid? AssignedBy { get; set; }
    public DateTime AssignedAt { get; set; }

    public Coach Coach { get; set; } = null!;
    public Athlete Athlete { get; set; } = null!;
    public Academy Academy { get; set; } = null!;
}
