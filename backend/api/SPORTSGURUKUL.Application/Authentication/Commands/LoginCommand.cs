using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Authentication.DTOs;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Authentication.Commands;

public sealed record LoginCommand(string Email, string Password) : IRequest<ApiResponse<AuthResponse>>;

public sealed class LoginCommandValidator : AbstractValidator<LoginCommand>
{
    public LoginCommandValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Invalid email address.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.");
    }
}

public sealed class LoginCommandHandler : IRequestHandler<LoginCommand, ApiResponse<AuthResponse>>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenPairService _tokenPairService;
    private readonly IClientInfoService _clientInfoService;
    private readonly ILogger<LoginCommandHandler> _logger;

    public LoginCommandHandler(
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        ITokenPairService tokenPairService,
        IClientInfoService clientInfoService,
        ILogger<LoginCommandHandler> logger)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _tokenPairService = tokenPairService;
        _clientInfoService = clientInfoService;
        _logger = logger;
    }

    public async Task<ApiResponse<AuthResponse>> Handle(LoginCommand command, CancellationToken cancellationToken)
    {
        var normalizedEmail = command.Email.Trim().ToUpperInvariant();

        var user = await _userRepository.GetByEmailWithRolesAsync(normalizedEmail, cancellationToken);

        if (user is null || !_passwordHasher.VerifyPassword(command.Password, user.PasswordHash))
        {
            _logger.LogWarning("Login failed for email {Email}", command.Email);
            throw AppException.Unauthorized("Invalid email or password.");
        }

        if (user.AccountStatus != AccountStatus.Active)
        {
            _logger.LogWarning(
                "Login blocked for email {Email}: account status {AccountStatus}",
                command.Email,
                user.AccountStatus);
            throw AppException.Forbidden(
                $"Your account is {user.AccountStatus.ToString().ToLowerInvariant()}. Please contact support.");
        }

        user.LastLoginAt = DateTime.UtcNow;
        user.Touch();
        await _userRepository.UpdateAsync(user, cancellationToken);

        var roles = user.UserRoles
            .Where(ur => ur.IsActive)
            .Select(ur => ur.Role.Name)
            .ToList();

        var response = await _tokenPairService.IssueTokenPairAsync(
            user,
            roles,
            _clientInfoService.IpAddress,
            cancellationToken: cancellationToken);

        _logger.LogInformation("User {UserId} signed in", user.Id);

        return ApiResponse<AuthResponse>.Ok(response, "Sign in successful.");
    }
}
