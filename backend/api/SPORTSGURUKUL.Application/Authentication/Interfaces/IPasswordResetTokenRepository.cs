using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Authentication.Interfaces;

public interface IPasswordResetTokenRepository
{
    Task<PasswordResetToken?> GetByTokenHashAsync(string tokenHash, CancellationToken cancellationToken = default);
    Task AddAsync(PasswordResetToken token, CancellationToken cancellationToken = default);
    Task UpdateAsync(PasswordResetToken token, CancellationToken cancellationToken = default);
    Task MarkAllUnusedAsUsedAsync(Guid userId, CancellationToken cancellationToken = default);
}
