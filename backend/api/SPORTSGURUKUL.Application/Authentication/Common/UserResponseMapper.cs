using SPORTSGURUKUL.Application.Authentication.DTOs;
using SPORTSGURUKUL.Domain.Constants;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Authentication.Common;

public static class UserResponseMapper
{
    public static UserResponse Map(User user, IReadOnlyList<string>? roleNames = null)
    {
        var roles = (roleNames ?? user.UserRoles
                .Where(ur => ur.IsActive)
                .Select(ur => ur.Role.Name))
            .ToList();

        var defaultRole = roles.FirstOrDefault() ?? RoleNames.AppUser;

        return new UserResponse
        {
            UserId = user.Id,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            MobileNumber = user.MobileNumber,
            Roles = roles,
            DefaultRole = defaultRole,
            AccountStatus = user.AccountStatus.ToString()
        };
    }
}
