using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Batches.Interfaces;

public interface IBatchRepository
{
    Task<List<Batch>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default);

    Task<Batch?> GetByIdForOwnerAsync(
        Guid batchId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default);

    Task AddAsync(Batch batch, CancellationToken cancellationToken = default);

    Task DeleteChildrenAsync(Guid batchId, CancellationToken cancellationToken = default);

    Task DeleteByIdAsync(Guid batchId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes the coach from every batch-coach association in the given academy.
    /// </summary>
    Task RemoveCoachFromBatchesAsync(
        Guid coachId,
        Guid academyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes the athlete from every batch-athlete association in the given academy.
    /// </summary>
    Task RemoveAthleteFromBatchesAsync(
        Guid athleteId,
        Guid academyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns every batch the coach is assigned to across all academies,
    /// including slots, coach peers, athlete associations and the academy/sport.
    /// </summary>
    Task<List<Batch>> GetByCoachAsync(
        Guid coachId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns every batch the athlete is assigned to across all academies,
    /// including slots, coach peers and the academy/sport. Athlete associations
    /// are intentionally not surfaced to the athlete themselves.
    /// </summary>
    Task<List<Batch>> GetByAthleteAsync(
        Guid athleteId,
        CancellationToken cancellationToken = default);

    void Detach(Batch batch);

    void ClearTracker();
}
