namespace SPORTSGURUKUL.Application.Authentication.DTOs;

public sealed class UserResponse
{
    public Guid UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;
    public List<string> Roles { get; set; } = [];
    public string DefaultRole { get; set; } = string.Empty;
    public string AccountStatus { get; set; } = string.Empty;
}
