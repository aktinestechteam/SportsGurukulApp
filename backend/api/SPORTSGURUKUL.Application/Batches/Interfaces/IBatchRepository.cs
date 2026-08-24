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

    void Detach(Batch batch);

    void ClearTracker();
}
