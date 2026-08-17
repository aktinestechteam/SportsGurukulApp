using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Common;
using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;
using SPORTSGURUKUL.Domain.Constants;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Coaches.Commands;

public sealed record CreateAcademyCoachCommand(
    Guid AcademyId,
    CreateCoachRequest Request) : IRequest<ApiResponse<CreateCoachResponse>>;

public sealed class CreateAcademyCoachCommandValidator : AbstractValidator<CreateAcademyCoachCommand>
{
    public CreateAcademyCoachCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy is required.");

        RuleFor(x => x.Request)
            .SetValidator(new CreateCoachRequestValidator());
    }
}

public sealed class CreateAcademyCoachCommandHandler
    : IRequestHandler<CreateAcademyCoachCommand, ApiResponse<CreateCoachResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRoleRepository _roleRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly IPublicUserIdGenerator _publicUserIdGenerator;
    private readonly ITemporaryPasswordGenerator _temporaryPasswordGenerator;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IEmailService _emailService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly AppOptions _appOptions;
    private readonly ILogger<CreateAcademyCoachCommandHandler> _logger;

    public CreateAcademyCoachCommandHandler(
        IAcademyRepository academyRepository,
        IUserRepository userRepository,
        IRoleRepository roleRepository,
        ICoachRepository coachRepository,
        ICoachAthleteRepository coachAthleteRepository,
        IPublicUserIdGenerator publicUserIdGenerator,
        ITemporaryPasswordGenerator temporaryPasswordGenerator,
        IPasswordHasher passwordHasher,
        IEmailService emailService,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        IOptions<AppOptions> appOptions,
        ILogger<CreateAcademyCoachCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _coachRepository = coachRepository;
        _coachAthleteRepository = coachAthleteRepository;
        _publicUserIdGenerator = publicUserIdGenerator;
        _temporaryPasswordGenerator = temporaryPasswordGenerator;
        _passwordHasher = passwordHasher;
        _emailService = emailService;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _appOptions = appOptions.Value;
        _logger = logger;
    }

    public async Task<ApiResponse<CreateCoachResponse>> Handle(
        CreateAcademyCoachCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to add a coach.");
        }

        var request = command.Request;

        // The whole coach creation (user, role, profile, academy association,
        // branch and sport links) is transactional. The invitation email is
        // sent before commit so that a failed email delivery rolls back the
        // account instead of leaving an orphaned user behind.
        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            var academy = await _academyRepository.GetByIdAsync(command.AcademyId, cancellationToken)
                ?? throw AppException.NotFound("Academy not found.");

            if (academy.OwnerUserId != ownerUserId)
            {
                throw AppException.Forbidden("You are not authorized to add a coach to this academy.");
            }

            var normalizedEmail = request.Email.Trim().ToUpperInvariant();
            var normalizedMobile = request.MobileNumber.Trim().ToUpperInvariant();

            if (await _userRepository.EmailExistsAsync(normalizedEmail, cancellationToken))
            {
                _logger.LogInformation(
                    "Add coach attempt with an already registered email {Email} for academy {AcademyId}",
                    request.Email,
                    command.AcademyId);
                throw AppException.Conflict("This email is already registered with Sports Gurukul.");
            }

            if (await _userRepository.MobileNumberExistsAsync(normalizedMobile, cancellationToken))
            {
                _logger.LogInformation(
                    "Add coach attempt with an already registered mobile for academy {AcademyId}",
                    command.AcademyId);
                throw AppException.Conflict("This mobile number is already registered with Sports Gurukul.");
            }

            var branchId = ResolveBranch(academy, request);
            var sports = ResolveSports(academy, request);
            var athleteIds = await ResolveAthleteIdsAsync(command.AcademyId, request, cancellationToken);

            var publicUserId = await _publicUserIdGenerator.GenerateAsync(
                _appOptions.UserIdPrefix,
                cancellationToken);

            var temporaryPassword = _temporaryPasswordGenerator.Generate();
            var now = DateTime.UtcNow;
            var userId = Guid.NewGuid();
            var coachId = Guid.NewGuid();

            var user = new User
            {
                Id = userId,
                FirstName = request.FirstName.Trim(),
                LastName = request.LastName.Trim(),
                Email = request.Email.Trim(),
                NormalizedEmail = normalizedEmail,
                MobileNumber = request.MobileNumber.Trim(),
                NormalizedMobileNumber = normalizedMobile,
                PublicUserId = publicUserId,
                PasswordHash = _passwordHasher.HashPassword(temporaryPassword),
                AccountStatus = AccountStatus.Active,
                IsEmailVerified = false,
                CreatedAt = now,
                UpdatedAt = now
            };

            var coachRole = await _roleRepository.GetByNameAsync(RoleNames.AcademyCoach, cancellationToken)
                ?? throw AppException.Conflict("The Academy Coach role is not configured.");

            user.UserRoles.Add(new UserRole
            {
                UserId = userId,
                RoleId = coachRole.Id,
                AssignedAt = now,
                AssignedBy = ownerUserId,
                IsActive = true
            });

            var coach = new Coach
            {
                Id = coachId,
                UserId = userId,
                User = user,
                CreatedAt = now,
                UpdatedAt = now
            };

            foreach (var sport in sports)
            {
                coach.Sports.Add(new CoachSport
                {
                    CoachId = coachId,
                    SportId = sport.SportId,
                    Specialization = sport.Specialization?.Trim(),
                    Sport = sport.Sport,
                    CreatedAt = now
                });
            }

            var association = new AcademyCoach
            {
                AcademyId = command.AcademyId,
                CoachId = coachId,
                BranchId = branchId?.Id,
                AssignedBy = ownerUserId,
                Status = CoachStatus.Invited,
                IsActive = true,
                AssignedAt = now,
                Academy = academy,
                Coach = coach,
                Branch = branchId
            };

            foreach (var athleteId in athleteIds)
            {
                coach.AthleteMappings.Add(new CoachAthlete
                {
                    CoachId = coachId,
                    AthleteId = athleteId,
                    AcademyId = command.AcademyId,
                    AssignedBy = ownerUserId,
                    AssignedAt = now
                });
            }

            await _userRepository.AddAsync(user, cancellationToken);
            await _coachRepository.AddAsync(coach, cancellationToken);
            await _coachRepository.AddAssociationAsync(association, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            var loginUrl = string.IsNullOrWhiteSpace(_appOptions.LoginBaseUrl)
                ? _appOptions.FrontendBaseUrl
                : _appOptions.LoginBaseUrl;

            var emailSent = await _emailService.SendCoachCredentialsAsync(
                user.Email,
                user.FirstName,
                academy.Name,
                publicUserId,
                temporaryPassword,
                loginUrl,
                cancellationToken);

            if (!emailSent)
            {
                _logger.LogWarning(
                    "Coach {CoachId} for academy {AcademyId} was not created because the welcome email could not be sent.",
                    coachId,
                    command.AcademyId);
                throw AppException.ServiceUnavailable(
                    "The coach could not be created because the welcome email could not be sent. Please try again.");
            }

            await _unitOfWork.CommitAsync(cancellationToken);

            var mappedAthletes = await _coachAthleteRepository.GetByCoachAndAcademyAsync(
                coachId,
                command.AcademyId,
                cancellationToken);

            _logger.LogInformation(
                "Coach {CoachId} ({PublicUserId}) added to academy {AcademyId} by {AssignedBy}",
                coachId,
                publicUserId,
                command.AcademyId,
                ownerUserId);

            return ApiResponse<CreateCoachResponse>.Ok(
                CoachResponseMapper.MapCreated(association, mappedAthletes),
                "Coach added successfully. Login credentials have been sent to the registered email address.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static AcademyBranch? ResolveBranch(Academy academy, CreateCoachRequest request)
    {
        if (request.BranchId is null)
        {
            if (academy.Branches.Count > 0)
            {
                throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException("branchId", "Please select a branch for this academy.");
            }

            return null;
        }

        var branch = academy.Branches.FirstOrDefault(b => b.Id == request.BranchId);
        if (branch is null)
        {
            throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException("branchId", "The selected branch does not belong to this academy.");
        }

        return branch;
    }

    private static List<CoachSport> ResolveSports(Academy academy, CreateCoachRequest request)
    {
        var academySports = academy.Sports.ToDictionary(s => s.Id);

        var sports = new List<CoachSport>(request.Sports.Count);
        foreach (var item in request.Sports)
        {
            if (!academySports.TryGetValue(item.SportId, out var academySport))
            {
                throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException("sports", "The selected sport does not belong to this academy.");
            }

            sports.Add(new CoachSport
            {
                SportId = item.SportId,
                Specialization = item.Specialization,
                Sport = academySport
            });
        }

        return sports;
    }

    private async Task<List<Guid>> ResolveAthleteIdsAsync(
        Guid academyId,
        CreateCoachRequest request,
        CancellationToken cancellationToken)
    {
        if (request.AthleteIds.Count == 0)
        {
            return [];
        }

        var academyAthleteIds = await _academyRepository.GetAcademyAthleteIdsAsync(
            academyId,
            cancellationToken);
        var allowed = academyAthleteIds.ToHashSet();

        var result = new List<Guid>(request.AthleteIds.Count);
        foreach (var athleteId in request.AthleteIds.Distinct())
        {
            if (!allowed.Contains(athleteId))
            {
                throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException(
                    "athleteIds",
                    "The selected athlete does not belong to this academy.");
            }

            result.Add(athleteId);
        }

        return result;
    }
}
