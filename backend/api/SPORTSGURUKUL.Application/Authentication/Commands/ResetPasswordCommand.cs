using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Authentication.Commands;

public sealed record ResetPasswordCommand(
    string Token,
    string NewPassword,
    string ConfirmPassword) : IRequest<ApiResponse<object>>;

public sealed class ResetPasswordCommandValidator : AbstractValidator<ResetPasswordCommand>
{
    public ResetPasswordCommandValidator()
    {
        RuleFor(x => x.Token)
            .NotEmpty().WithMessage("Token is required.");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("New password is required.")
            .Matches(PasswordPolicy.Pattern).WithMessage(PasswordPolicy.Message);

        RuleFor(x => x.ConfirmPassword)
            .NotEmpty().WithMessage("Confirm password is required.")
            .Equal(x => x.NewPassword).WithMessage("Passwords do not match.");
    }
}

public sealed class ResetPasswordCommandHandler : IRequestHandler<ResetPasswordCommand, ApiResponse<object>>
{
    private readonly IPasswordResetTokenRepository _passwordResetTokenRepository;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ISecureTokenService _secureTokenService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<ResetPasswordCommandHandler> _logger;

    public ResetPasswordCommandHandler(
        IPasswordResetTokenRepository passwordResetTokenRepository,
        IRefreshTokenRepository refreshTokenRepository,
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        ISecureTokenService secureTokenService,
        IUnitOfWork unitOfWork,
        ILogger<ResetPasswordCommandHandler> logger)
    {
        _passwordResetTokenRepository = passwordResetTokenRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _secureTokenService = secureTokenService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(ResetPasswordCommand command, CancellationToken cancellationToken)
    {
        var tokenHash = _secureTokenService.HashToken(command.Token);
        var stored = await _passwordResetTokenRepository.GetByTokenHashAsync(tokenHash, cancellationToken);

        if (stored is null || stored.UsedAt is not null || DateTime.UtcNow >= stored.ExpiresAt)
        {
            _logger.LogWarning("Invalid, expired or already-used password reset token submitted");
            throw AppException.BadRequest("This password reset link is invalid or has expired.");
        }

        var user = await _userRepository.GetByIdAsync(stored.UserId, cancellationToken)
            ?? throw AppException.BadRequest("This password reset link is invalid or has expired.");

        if (user.AccountStatus != AccountStatus.Active)
        {
            throw AppException.Forbidden(
                $"Your account is {user.AccountStatus.ToString().ToLowerInvariant()}. Please contact support.");
        }

        user.PasswordHash = _passwordHasher.HashPassword(command.NewPassword);
        user.Touch();
        stored.UsedAt = DateTime.UtcNow;

        await _userRepository.UpdateAsync(user, cancellationToken);
        await _passwordResetTokenRepository.UpdateAsync(stored, cancellationToken);
        await _refreshTokenRepository.RevokeAllForUserAsync(user.Id, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Password reset completed for user {UserId}", user.Id);

        return ApiResponse<object>.OkNoData("Your password has been reset successfully. Please sign in.");
    }
}
