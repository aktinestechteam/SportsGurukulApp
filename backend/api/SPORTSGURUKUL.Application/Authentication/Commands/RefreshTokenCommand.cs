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

public sealed record RefreshTokenCommand(string RefreshToken) : IRequest<ApiResponse<AuthResponse>>;

public sealed class RefreshTokenCommandValidator : AbstractValidator<RefreshTokenCommand>
{
    public RefreshTokenCommandValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("Refresh token is required.");
    }
}

public sealed class RefreshTokenCommandHandler : IRequestHandler<RefreshTokenCommand, ApiResponse<AuthResponse>>
{
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IUserRepository _userRepository;
    private readonly ISecureTokenService _secureTokenService;
    private readonly ITokenPairService _tokenPairService;
    private readonly IClientInfoService _clientInfoService;
    private readonly ILogger<RefreshTokenCommandHandler> _logger;

    public RefreshTokenCommandHandler(
        IRefreshTokenRepository refreshTokenRepository,
        IUserRepository userRepository,
        ISecureTokenService secureTokenService,
        ITokenPairService tokenPairService,
        IClientInfoService clientInfoService,
        ILogger<RefreshTokenCommandHandler> logger)
    {
        _refreshTokenRepository = refreshTokenRepository;
        _userRepository = userRepository;
        _secureTokenService = secureTokenService;
        _tokenPairService = tokenPairService;
        _clientInfoService = clientInfoService;
        _logger = logger;
    }

    public async Task<ApiResponse<AuthResponse>> Handle(RefreshTokenCommand command, CancellationToken cancellationToken)
    {
        var tokenHash = _secureTokenService.HashToken(command.RefreshToken);
        var stored = await _refreshTokenRepository.GetByTokenHashWithUserAsync(tokenHash, cancellationToken);

        if (stored is null)
        {
            throw AppException.Unauthorized("Invalid refresh token.");
        }

        if (stored.RevokedAt is not null)
        {
            _logger.LogWarning("Refresh token {TokenId} has been revoked", stored.Id);
            throw AppException.Unauthorized("Refresh token has been revoked.");
        }

        if (stored.IsExpired)
        {
            _logger.LogWarning("Refresh token {TokenId} has expired", stored.Id);
            throw AppException.Unauthorized("Refresh token has expired.");
        }

        var user = stored.User;
        if (user is null || user.AccountStatus != AccountStatus.Active)
        {
            throw AppException.Forbidden("Your account is not active. Please contact support.");
        }

        var roles = await _userRepository.GetRoleNamesAsync(user.Id, cancellationToken);

        var response = await _tokenPairService.IssueTokenPairAsync(
            user,
            roles,
            _clientInfoService.IpAddress,
            rotatedOutToken: stored,
            cancellationToken: cancellationToken);

        _logger.LogInformation("Refresh token rotated for user {UserId}", user.Id);

        return ApiResponse<AuthResponse>.Ok(response, "Tokens refreshed successfully.");
    }
}
