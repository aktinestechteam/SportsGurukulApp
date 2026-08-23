using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Authentication.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken = default);
    Task<User?> GetByEmailWithRolesAsync(string normalizedEmail, CancellationToken cancellationToken = default);
    Task<User?> GetByIdWithRolesAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<bool> EmailExistsAsync(string normalizedEmail, CancellationToken cancellationToken = default);
    Task<bool> MobileNumberExistsAsync(string normalizedMobileNumber, CancellationToken cancellationToken = default);
    Task<bool> EmailExistsExcludingAsync(string normalizedEmail, Guid excludeUserId, CancellationToken cancellationToken = default);
    Task<bool> MobileNumberExistsExcludingAsync(string normalizedMobileNumber, Guid excludeUserId, CancellationToken cancellationToken = default);
    Task<bool> PublicUserIdExistsAsync(string publicUserId, CancellationToken cancellationToken = default);
    Task AddAsync(User user, CancellationToken cancellationToken = default);
    Task UpdateAsync(User user, CancellationToken cancellationToken = default);
    Task<List<string>> GetRoleNamesAsync(Guid userId, CancellationToken cancellationToken = default);
    Task RemoveRolesAsync(Guid userId, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default);
}
