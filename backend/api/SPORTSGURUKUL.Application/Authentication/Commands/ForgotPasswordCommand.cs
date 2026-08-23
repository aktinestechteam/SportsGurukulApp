using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Authentication.Commands;

public sealed record ForgotPasswordCommand(string Email) : IRequest<ApiResponse<object>>;

public sealed class ForgotPasswordCommandValidator : AbstractValidator<ForgotPasswordCommand>
{
    public ForgotPasswordCommandValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Invalid email address.");
    }
}

public sealed class ForgotPasswordCommandHandler : IRequestHandler<ForgotPasswordCommand, ApiResponse<object>>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordResetTokenRepository _passwordResetTokenRepository;
    private readonly ISecureTokenService _secureTokenService;
    private readonly IEmailService _emailService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly EmailOptions _emailOptions;
    private readonly AppOptions _appOptions;
    private readonly ILogger<ForgotPasswordCommandHandler> _logger;

    public ForgotPasswordCommandHandler(
        IUserRepository userRepository,
        IPasswordResetTokenRepository passwordResetTokenRepository,
        ISecureTokenService secureTokenService,
        IEmailService emailService,
        IUnitOfWork unitOfWork,
        IOptions<EmailOptions> emailOptions,
        IOptions<AppOptions> appOptions,
        ILogger<ForgotPasswordCommandHandler> logger)
    {
        _userRepository = userRepository;
        _passwordResetTokenRepository = passwordResetTokenRepository;
        _secureTokenService = secureTokenService;
        _emailService = emailService;
        _unitOfWork = unitOfWork;
        _emailOptions = emailOptions.Value;
        _appOptions = appOptions.Value;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(ForgotPasswordCommand command, CancellationToken cancellationToken)
    {
        var normalizedEmail = command.Email.Trim().ToUpperInvariant();
        var user = await _userRepository.GetByEmailAsync(normalizedEmail, cancellationToken);

        if (user is not null && user.AccountStatus == AccountStatus.Active)
        {
            var plainTextToken = _secureTokenService.GenerateToken();

            var resetToken = new PasswordResetToken
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                TokenHash = _secureTokenService.HashToken(plainTextToken),
                ExpiresAt = DateTime.UtcNow.AddMinutes(_emailOptions.ResetTokenLifetimeMinutes),
                CreatedAt = DateTime.UtcNow
            };

            await _passwordResetTokenRepository.MarkAllUnusedAsUsedAsync(user.Id, cancellationToken);
            await _passwordResetTokenRepository.AddAsync(resetToken, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            var resetUrl = $"{_appOptions.ResetPasswordBaseUrl}?token={plainTextToken}";
            await _emailService.SendPasswordResetAsync(user.Email, user.FirstName, resetUrl, cancellationToken);

            _logger.LogInformation("Password reset requested for user {UserId}", user.Id);
        }

        return ApiResponse<object>.OkNoData(
            "If an account exists for this email, password reset instructions have been sent.");
    }
}
