namespace SPORTSGURUKUL.Application.Coaches.DTOs;

/// <summary>
/// Pairs a sport with the set of coaches assigned to an athlete for that sport.
/// Used when persisting athlete→coach per-sport mappings.
/// </summary>
public sealed class SportCoachAssignment
{
    public Guid SportId { get; set; }
    public IEnumerable<Guid> CoachIds { get; set; } = [];
}

/// <summary>
/// Pairs a sport with the set of athletes assigned to a coach for that sport.
/// Used when persisting coach→athlete per-sport mappings.
/// </summary>
public sealed class SportAthleteAssignment
{
    public Guid SportId { get; set; }
    public IEnumerable<Guid> AthleteIds { get; set; } = [];
}
