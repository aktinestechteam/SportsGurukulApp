using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Coaches.Interfaces;

/// <summary>
/// Repository for the coach-athlete-sport many-to-many mapping scoped to an academy.
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
    /// Loads every coach-athlete mapping for the given athlete across all
    /// academies, including the mapped coach identity.
    /// </summary>
    Task<List<CoachAthlete>> GetByAthleteAsync(
        Guid athleteId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Replaces the full set of athlete mappings for a coach within an academy.
    /// The mappings are grouped by sport; existing mappings for the coach and
    /// academy are removed and the given set is added, preventing duplicates.
    /// </summary>
    Task ReplaceCoachMappingsAsync(
        Guid coachId,
        Guid academyId,
        IEnumerable<SportAthleteAssignment> assignments,
        Guid assignedBy,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Replaces the full set of coach mappings for an athlete within an academy.
    /// The mappings are grouped by sport; existing mappings for the athlete and
    /// academy are removed and the given set is added, preventing duplicates.
    /// </summary>
    Task ReplaceAthleteMappingsAsync(
        Guid athleteId,
        Guid academyId,
        IEnumerable<SportCoachAssignment> assignments,
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

    /// <summary>
    /// Loads every coach-athlete mapping for the given coach across all
    /// academies, including the mapped athlete identity and academy.
    /// </summary>
    Task<List<CoachAthlete>> GetByCoachAsync(
        Guid coachId,
        CancellationToken cancellationToken = default);
}
