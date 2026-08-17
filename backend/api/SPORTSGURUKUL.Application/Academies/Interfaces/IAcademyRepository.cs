using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Academies.Interfaces;

public interface IAcademyRepository
{
    Task<List<Academy>> GetByOwnerAsync(Guid ownerUserId, CancellationToken cancellationToken = default);

    Task<Academy?> GetByIdAsync(
        Guid academyId,
        CancellationToken cancellationToken = default);

    Task<Academy?> GetByIdForOwnerAsync(
        Guid academyId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default);

    Task<bool> ExistsForOwnerAsync(
        Guid academyId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the ids of every athlete associated with the academy.
    /// </summary>
    Task<List<Guid>> GetAcademyAthleteIdsAsync(
        Guid academyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns the ids of every coach associated with the academy.
    /// </summary>
    Task<List<Guid>> GetAcademyCoachIdsAsync(
        Guid academyId,
        CancellationToken cancellationToken = default);

    Task AddAsync(Academy academy, CancellationToken cancellationToken = default);

    Task UpdateAsync(Academy academy, CancellationToken cancellationToken = default);

    Task DeleteAsync(Academy academy, CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes every athlete and coach association row for the given academy.
    /// </summary>
    Task RemoveAssociationsAsync(Guid academyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes the academy's owned child rows (working hours, memberships,
    /// facilities, sports and branches). Must be called after all athlete and
    /// coach associations for the academy have been removed.
    /// </summary>
    Task DeleteChildrenAsync(Guid academyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes the academy row itself.
    /// </summary>
    Task DeleteByIdAsync(Guid academyId, CancellationToken cancellationToken = default);
}
