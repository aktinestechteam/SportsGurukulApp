using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Authentication.Interfaces;

public interface IRoleRepository
{
    Task<Role?> GetByNameAsync(string name, CancellationToken cancellationToken = default);
    Task<Role?> GetAppUserRoleAsync(CancellationToken cancellationToken = default);
}
