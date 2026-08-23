using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Authentication.DTOs;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Authentication.Common;

public interface ITokenPairService
{
    Task<AuthResponse> IssueTokenPairAsync(
        User user,
        IReadOnlyList<string> roles,
        string? ipAddress,
        RefreshToken? rotatedOutToken = null,
        CancellationToken cancellationToken = default);
}

public class TokenPairService : ITokenPairService
{
    private readonly IJwtService _jwtService;
    private readonly ISecureTokenService _secureTokenService;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly JwtOptions _jwtOptions;

    public TokenPairService(
        IJwtService jwtService,
        ISecureTokenService secureTokenService,
        IRefreshTokenRepository refreshTokenRepository,
        IUnitOfWork unitOfWork,
        IOptions<JwtOptions> jwtOptions)
    {
        _jwtService = jwtService;
        _secureTokenService = secureTokenService;
        _refreshTokenRepository = refreshTokenRepository;
        _unitOfWork = unitOfWork;
        _jwtOptions = jwtOptions.Value;
    }

    public async Task<AuthResponse> IssueTokenPairAsync(
        User user,
        IReadOnlyList<string> roles,
        string? ipAddress,
        RefreshToken? rotatedOutToken = null,
        CancellationToken cancellationToken = default)
    {
        var (accessToken, expiresAt) = _jwtService.GenerateAccessToken(user, roles);

        var refreshToken = CreateRefreshToken(user.Id, ipAddress);

        if (rotatedOutToken is { RevokedAt: null })
        {
            rotatedOutToken.RevokedAt = DateTime.UtcNow;
            rotatedOutToken.RevokedByIp = ipAddress;
            rotatedOutToken.ReplacedByTokenId = refreshToken.Id;
        }

        await _refreshTokenRepository.AddAsync(refreshToken, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new AuthResponse
        {
            AccessToken = accessToken,
            AccessTokenExpiresAt = expiresAt,
            RefreshToken = refreshToken.RawToken,
            User = UserResponseMapper.Map(user, roles)
        };
    }

    private RefreshToken CreateRefreshToken(Guid userId, string? ipAddress)
    {
        var plainText = _secureTokenService.GenerateToken();

        return new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            TokenHash = _secureTokenService.HashToken(plainText),
            ExpiresAt = DateTime.UtcNow.AddDays(_jwtOptions.RefreshTokenDays),
            CreatedAt = DateTime.UtcNow,
            CreatedByIp = ipAddress,
            RawToken = plainText
        };
    }
}
