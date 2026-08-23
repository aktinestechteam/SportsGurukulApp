using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Authentication.Interfaces;

public interface IJwtService
{
    (string Token, DateTime ExpiresAt) GenerateAccessToken(User user, IReadOnlyList<string> roles);
}
