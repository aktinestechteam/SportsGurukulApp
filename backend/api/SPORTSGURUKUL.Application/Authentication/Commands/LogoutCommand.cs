using FluentValidation;
using MediatR;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Authentication.Commands;

public sealed record LogoutCommand(string RefreshToken) : IRequest<ApiResponse<object>>;

public sealed class LogoutCommandValidator : AbstractValidator<LogoutCommand>
{
    public LogoutCommandValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("Refresh token is required.");
    }
}

public sealed class LogoutCommandHandler : IRequestHandler<LogoutCommand, ApiResponse<object>>
{
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly ISecureTokenService _secureTokenService;
    private readonly IClientInfoService _clientInfoService;
    private readonly IUnitOfWork _unitOfWork;

    public LogoutCommandHandler(
        IRefreshTokenRepository refreshTokenRepository,
        ISecureTokenService secureTokenService,
        IClientInfoService clientInfoService,
        IUnitOfWork unitOfWork)
    {
        _refreshTokenRepository = refreshTokenRepository;
        _secureTokenService = secureTokenService;
        _clientInfoService = clientInfoService;
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<object>> Handle(LogoutCommand command, CancellationToken cancellationToken)
    {
        var tokenHash = _secureTokenService.HashToken(command.RefreshToken);
        var stored = await _refreshTokenRepository.GetByTokenHashAsync(tokenHash, cancellationToken);

        if (stored is { RevokedAt: null })
        {
            stored.RevokedAt = DateTime.UtcNow;
            stored.RevokedByIp = _clientInfoService.IpAddress;
            await _refreshTokenRepository.UpdateAsync(stored, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return ApiResponse<object>.OkNoData("Signed out successfully.");
    }
}
