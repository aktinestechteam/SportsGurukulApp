using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Authentication.DTOs;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
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
    private readonly IUserRepository _userRepository;
    private readonly IRoleRepository _roleRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<RegisterCommandHandler> _logger;

    public RegisterCommandHandler(
        IUserRepository userRepository,
        IRoleRepository roleRepository,
        IPasswordHasher passwordHasher,
        IUnitOfWork unitOfWork,
        ILogger<RegisterCommandHandler> logger)
    {
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _passwordHasher = passwordHasher;
        _unitOfWork = unitOfWork;
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
        var user = new User
        {
            Id = userId,
            FirstName = command.FirstName.Trim(),
            LastName = command.LastName.Trim(),
            Email = command.Email.Trim(),
            NormalizedEmail = normalizedEmail,
            MobileNumber = command.MobileNumber.Trim(),
            NormalizedMobileNumber = command.MobileNumber.Trim().ToUpperInvariant(),
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

        _logger.LogInformation("User {UserId} registered successfully", user.Id);

        return ApiResponse<UserResponse>.Ok(
            UserResponseMapper.Map(user),
            "Registration successful. Please sign in.");
    }
}
