using MediatR;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Authentication.DTOs;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Authentication.Queries;

public sealed record GetCurrentUserQuery : IRequest<ApiResponse<UserResponse>>;

public sealed class GetCurrentUserQueryHandler : IRequestHandler<GetCurrentUserQuery, ApiResponse<UserResponse>>
{
    private readonly IUserRepository _userRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetCurrentUserQueryHandler(
        IUserRepository userRepository,
        ICurrentUserService currentUserService)
    {
        _userRepository = userRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ApiResponse<UserResponse>> Handle(GetCurrentUserQuery query, CancellationToken cancellationToken)
    {
        if (!_currentUserService.IsAuthenticated)
        {
            throw AppException.Unauthorized("You must be signed in.");
        }

        var user = await _userRepository.GetByIdWithRolesAsync(_currentUserService.UserId, cancellationToken)
            ?? throw AppException.NotFound("User not found.");

        var roles = user.UserRoles
            .Where(ur => ur.IsActive)
            .Select(ur => ur.Role.Name)
            .ToList();

        return ApiResponse<UserResponse>.Ok(
            UserResponseMapper.Map(user, roles),
            "User retrieved successfully.");
    }
}
