using System.Security.Cryptography;
using System.Text;
using SPORTSGURUKUL.Application.Authentication.Interfaces;

namespace SPORTSGURUKUL.Infrastructure.Security;

public class SecureTokenService : ISecureTokenService
{
    public string GenerateToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
    }

    public string HashToken(string token)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToBase64String(hash);
    }
}
