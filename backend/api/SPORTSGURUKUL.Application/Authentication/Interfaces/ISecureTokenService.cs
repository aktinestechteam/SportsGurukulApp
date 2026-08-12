namespace SPORTSGURUKUL.Application.Authentication.Interfaces;

public interface ISecureTokenService
{
    string GenerateToken();
    string HashToken(string token);
}
