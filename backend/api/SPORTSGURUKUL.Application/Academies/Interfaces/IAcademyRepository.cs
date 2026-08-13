using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Academies.Interfaces;

public interface IAcademyRepository
{
    Task<List<Academy>> GetByOwnerAsync(Guid ownerUserId, CancellationToken cancellationToken = default);

    Task<Academy?> GetByIdForOwnerAsync(
        Guid academyId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default);

    Task<bool> ExistsForOwnerAsync(
        Guid academyId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default);

    Task AddAsync(Academy academy, CancellationToken cancellationToken = default);

    Task UpdateAsync(Academy academy, CancellationToken cancellationToken = default);

    Task DeleteAsync(Academy academy, CancellationToken cancellationToken = default);
}
