namespace SPORTSGURUKUL.Application.Authentication.DTOs;

public sealed class LogoutRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}
