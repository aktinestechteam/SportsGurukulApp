using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Coaches.Interfaces;

/// <summary>
/// Repository for the coach-athlete many-to-many mapping scoped to an academy.
/// </summary>
public interface ICoachAthleteRepository
{
    /// <summary>
    /// Loads every coach-athlete mapping for the given academy including the
    /// mapped athlete and coach identities.
    /// </summary>
    Task<List<CoachAthlete>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Loads the mappings for a specific coach within an academy, including the
    /// mapped athlete identity.
    /// </summary>
    Task<List<CoachAthlete>> GetByCoachAndAcademyAsync(
        Guid coachId,
        Guid academyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Loads the mappings for a specific athlete within an academy, including
    /// the mapped coach identity.
    /// </summary>
    Task<List<CoachAthlete>> GetByAthleteAndAcademyAsync(
        Guid athleteId,
        Guid academyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Replaces the set of athletes mapped to a coach within an academy. Existing
    /// mappings for the pair are removed and the given set is added, preventing
    /// duplicate coach-athlete records.
    /// </summary>
    Task ReplaceCoachMappingsAsync(
        Guid coachId,
        Guid academyId,
        IEnumerable<Guid> athleteIds,
        Guid assignedBy,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Replaces the set of coaches mapped to an athlete within an academy. Existing
    /// mappings for the pair are removed and the given set is added, preventing
    /// duplicate coach-athlete records.
    /// </summary>
    Task ReplaceAthleteMappingsAsync(
        Guid athleteId,
        Guid academyId,
        IEnumerable<Guid> coachIds,
        Guid assignedBy,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes every coach-athlete mapping for the given coach
    /// within the academy.
    /// </summary>
    Task RemoveByCoachAsync(
        Guid coachId,
        Guid academyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes every coach-athlete mapping for the given athlete
    /// within the academy.
    /// </summary>
    Task RemoveByAthleteAsync(
        Guid athleteId,
        Guid academyId,
        CancellationToken cancellationToken = default);
}
