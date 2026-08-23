using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Authentication.DTOs;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Authentication.Commands;

public sealed record RegisterCommand(
    string FirstName,
    string LastName,
    string Email,
    string MobileNumber,
    string Password,
    string ConfirmPassword,
    bool AcceptTerms) : IRequest<ApiResponse<UserResponse>>;

public sealed class RegisterCommandValidator : AbstractValidator<RegisterCommand>
{
    public RegisterCommandValidator()
    {
        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("First name is required.")
            .MaximumLength(100).WithMessage("First name must not exceed 100 characters.");

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("Last name is required.")
            .MaximumLength(100).WithMessage("Last name must not exceed 100 characters.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Invalid email address.")
            .MaximumLength(256).WithMessage("Email must not exceed 256 characters.");

        RuleFor(x => x.MobileNumber)
            .NotEmpty().WithMessage("Mobile number is required.")
            .Matches(PasswordPolicy.MobilePattern).WithMessage(PasswordPolicy.MobileMessage);

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            .Matches(PasswordPolicy.Pattern).WithMessage(PasswordPolicy.Message);

        RuleFor(x => x.ConfirmPassword)
            .NotEmpty().WithMessage("Confirm password is required.")
            .Equal(x => x.Password).WithMessage("Passwords do not match.");

        RuleFor(x => x.AcceptTerms)
            .Equal(true).WithMessage("You must accept the terms and conditions.");
    }
}

public sealed class RegisterCommandHandler : IRequestHandler<RegisterCommand, ApiResponse<UserResponse>>
{
    private const int MaxPublicUserIdAttempts = 5;

    private readonly IUserRepository _userRepository;
    private readonly IRoleRepository _roleRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IPublicUserIdGenerator _publicUserIdGenerator;
    private readonly IUnitOfWork _unitOfWork;
    private readonly AppOptions _appOptions;
    private readonly ILogger<RegisterCommandHandler> _logger;

    public RegisterCommandHandler(
        IUserRepository userRepository,
        IRoleRepository roleRepository,
        IPasswordHasher passwordHasher,
        IPublicUserIdGenerator publicUserIdGenerator,
        IUnitOfWork unitOfWork,
        IOptions<AppOptions> appOptions,
        ILogger<RegisterCommandHandler> logger)
    {
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _passwordHasher = passwordHasher;
        _publicUserIdGenerator = publicUserIdGenerator;
        _unitOfWork = unitOfWork;
        _appOptions = appOptions.Value;
        _logger = logger;
    }

    public async Task<ApiResponse<UserResponse>> Handle(RegisterCommand command, CancellationToken cancellationToken)
    {
        var normalizedEmail = command.Email.Trim().ToUpperInvariant();

        if (await _userRepository.EmailExistsAsync(normalizedEmail, cancellationToken))
        {
            _logger.LogInformation("Registration attempt with an already registered email {Email}", command.Email);
            throw AppException.Conflict("Email is already registered.");
        }

        var appUserRole = await _roleRepository.GetAppUserRoleAsync(cancellationToken)
            ?? throw AppException.Conflict("Default role is not configured.");

        var now = DateTime.UtcNow;
        var userId = Guid.NewGuid();
        var publicUserId = await GenerateUniquePublicUserIdAsync(cancellationToken);

        var user = new User
        {
            Id = userId,
            FirstName = command.FirstName.Trim(),
            LastName = command.LastName.Trim(),
            Email = command.Email.Trim(),
            NormalizedEmail = normalizedEmail,
            MobileNumber = command.MobileNumber.Trim(),
            NormalizedMobileNumber = command.MobileNumber.Trim().ToUpperInvariant(),
            PublicUserId = publicUserId,
            PasswordHash = _passwordHasher.HashPassword(command.Password),
            AccountStatus = AccountStatus.Active,
            IsEmailVerified = false,
            CreatedAt = now,
            UpdatedAt = now
        };

        user.UserRoles.Add(new UserRole
        {
            UserId = userId,
            RoleId = appUserRole.Id,
            AssignedAt = now,
            AssignedBy = null,
            IsActive = true
        });

        await _userRepository.AddAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "User {UserId} ({PublicUserId}) registered successfully",
            user.Id,
            user.PublicUserId);

        return ApiResponse<UserResponse>.Ok(
            UserResponseMapper.Map(user),
            "Registration successful. Please sign in.");
    }

    private async Task<string> GenerateUniquePublicUserIdAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 1; attempt <= MaxPublicUserIdAttempts; attempt++)
        {
            var candidate = await _publicUserIdGenerator.GenerateAsync(
                _appOptions.UserUserIdPrefix,
                cancellationToken);

            if (!await _userRepository.PublicUserIdExistsAsync(candidate, cancellationToken))
            {
                return candidate;
            }

            _logger.LogWarning(
                "Public user id collision for prefix {Prefix} on attempt {Attempt}; retrying.",
                _appOptions.UserUserIdPrefix,
                attempt);
        }

        throw AppException.ServiceUnavailable(
            "Registration could not be completed because a unique user identifier could not be generated. Please try again.");
    }
}
