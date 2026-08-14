using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Coaches.Interfaces;

public interface ICoachRepository
{
    /// <summary>
    /// Loads the academy coach associations for the given academy including
    /// the coach profile, user identity, branch and sport assignments.
    /// </summary>
    Task<List<AcademyCoach>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default);

    Task AddAsync(Coach coach, CancellationToken cancellationToken = default);

    Task AddAssociationAsync(AcademyCoach association, CancellationToken cancellationToken = default);

    /// <summary>
    /// Loads the coach association for a specific academy/coach pair including
    /// the academy, branch, coach profile, user identity and sport assignments.
    /// </summary>
    Task<AcademyCoach?> GetByAcademyAndCoachAsync(
        Guid academyId,
        Guid coachId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Loads the coach association for a specific academy/coach pair without
    /// change tracking, returning a detached snapshot of the current state.
    /// </summary>
    Task<AcademyCoach?> GetByAcademyAndCoachAsNoTrackingAsync(
        Guid academyId,
        Guid coachId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns true when the coach is associated with any academy other than
    /// the given one.
    /// </summary>
    Task<bool> HasOtherAssociationsAsync(
        Guid coachId,
        Guid exceptAcademyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes the coach's sport assignments and adds the new set in a single
    /// unit of work. The coach's in-memory Sports collection is replaced so
    /// mappers can read the resulting assignments.
    /// </summary>
    Task ReplaceSportsAsync(
        Coach coach,
        IEnumerable<CoachSport> newSports,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes the academy/coach association row.
    /// </summary>
    Task RemoveAssociationAsync(
        Guid academyId,
        Guid coachId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes the coach profile and all of its sport assignments.
    /// </summary>
    Task RemoveCoachAsync(Guid coachId, CancellationToken cancellationToken = default);
}
