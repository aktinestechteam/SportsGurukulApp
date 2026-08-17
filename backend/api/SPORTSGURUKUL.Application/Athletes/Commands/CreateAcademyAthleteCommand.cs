using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Common;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;
using SPORTSGURUKUL.Domain.Constants;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Athletes.Commands;

public sealed record CreateAcademyAthleteCommand(
    Guid AcademyId,
    CreateAthleteRequest Request) : IRequest<ApiResponse<CreateAthleteResponse>>;

public sealed class CreateAcademyAthleteCommandValidator : AbstractValidator<CreateAcademyAthleteCommand>
{
    public CreateAcademyAthleteCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy is required.");

        RuleFor(x => x.Request)
            .SetValidator(new CreateAthleteRequestValidator());
    }
}

public sealed class CreateAcademyAthleteCommandHandler
    : IRequestHandler<CreateAcademyAthleteCommand, ApiResponse<CreateAthleteResponse>>
{
    private const int MaxPublicUserIdAttempts = 5;

    private readonly IAcademyRepository _academyRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRoleRepository _roleRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly IPublicUserIdGenerator _publicUserIdGenerator;
    private readonly ITemporaryPasswordGenerator _temporaryPasswordGenerator;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IEmailService _emailService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly AppOptions _appOptions;
    private readonly ILogger<CreateAcademyAthleteCommandHandler> _logger;

    public CreateAcademyAthleteCommandHandler(
        IAcademyRepository academyRepository,
        IUserRepository userRepository,
        IRoleRepository roleRepository,
        IAthleteRepository athleteRepository,
        ICoachAthleteRepository coachAthleteRepository,
        IPublicUserIdGenerator publicUserIdGenerator,
        ITemporaryPasswordGenerator temporaryPasswordGenerator,
        IPasswordHasher passwordHasher,
        IEmailService emailService,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        IOptions<AppOptions> appOptions,
        ILogger<CreateAcademyAthleteCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _userRepository = userRepository;
        _roleRepository = roleRepository;
        _athleteRepository = athleteRepository;
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

    public async Task<ApiResponse<CreateAthleteResponse>> Handle(
        CreateAcademyAthleteCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (!_currentUserService.IsAuthenticated || ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to add an athlete.");
        }

        var request = command.Request;

        // The whole athlete creation (user, role, profile, academy association,
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
                throw AppException.Forbidden("You are not authorized to add an athlete to this academy.");
            }

            var normalizedEmail = request.Email.Trim().ToUpperInvariant();
            var normalizedMobile = request.MobileNumber.Trim().ToUpperInvariant();

            if (await _userRepository.EmailExistsAsync(normalizedEmail, cancellationToken))
            {
                _logger.LogInformation(
                    "Add athlete attempt with an already registered email {Email} for academy {AcademyId}",
                    request.Email,
                    command.AcademyId);
                throw AppException.Conflict("This email is already registered with Sports Gurukul.");
            }

            if (await _userRepository.MobileNumberExistsAsync(normalizedMobile, cancellationToken))
            {
                _logger.LogInformation(
                    "Add athlete attempt with an already registered mobile for academy {AcademyId}",
                    command.AcademyId);
                throw AppException.Conflict("This mobile number is already registered with Sports Gurukul.");
            }

            var branchId = ResolveBranch(academy, request);
            var primarySport = ResolvePrimarySport(academy, request);
            var secondarySport = ResolveSecondarySport(academy, request, primarySport.Id);
            var coachIds = await ResolveCoachIdsAsync(command.AcademyId, request, cancellationToken);

            var publicUserId = await GenerateUniquePublicUserIdAsync(cancellationToken);

            var temporaryPassword = _temporaryPasswordGenerator.Generate();
            var now = DateTime.UtcNow;
            var userId = Guid.NewGuid();
            var athleteId = Guid.NewGuid();

            // Date-only payloads (e.g. "2011-01-01") deserialize to a DateTime
            // with Kind=Unspecified, which Npgsql rejects for timestamptz
            // columns. Normalize to UTC midnight before persisting.
            var dateOfBirth = DateTime.SpecifyKind(request.DateOfBirth.Date, DateTimeKind.Utc);

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

            var athleteRole = await _roleRepository.GetByNameAsync(RoleNames.AcademyAthlete, cancellationToken)
                ?? throw AppException.Conflict("The Academy Athlete role is not configured.");

            user.UserRoles.Add(new UserRole
            {
                UserId = userId,
                RoleId = athleteRole.Id,
                AssignedAt = now,
                AssignedBy = ownerUserId,
                IsActive = true
            });

            var athlete = new Athlete
            {
                Id = athleteId,
                UserId = userId,
                User = user,
                DateOfBirth = dateOfBirth,
                Gender = request.Gender ?? AthleteGender.Male,
                Address = request.Address?.Trim(),
                EmergencyContact = request.EmergencyContact?.Trim(),
                AgeGroup = AgeGroupCalculator.CalculateAgeGroup(dateOfBirth),
                JoinedAt = now,
                CreatedAt = now,
                UpdatedAt = now
            };

            athlete.Sports.Add(new AthleteSport
            {
                AthleteId = athleteId,
                SportId = primarySport.Id,
                IsPrimary = true,
                Sport = primarySport,
                CreatedAt = now
            });

            if (secondarySport is not null)
            {
                athlete.Sports.Add(new AthleteSport
                {
                    AthleteId = athleteId,
                    SportId = secondarySport.Id,
                    IsPrimary = false,
                    Sport = secondarySport,
                    CreatedAt = now
                });
            }

            var association = new AcademyAthlete
            {
                AcademyId = command.AcademyId,
                AthleteId = athleteId,
                BranchId = branchId?.Id,
                AssignedBy = ownerUserId,
                Status = AthleteStatus.Invited,
                IsActive = true,
                AssignedAt = now,
                JoinedAt = now,
                Academy = academy,
                Athlete = athlete,
                Branch = branchId
            };

            foreach (var coachId in coachIds)
            {
                athlete.CoachMappings.Add(new CoachAthlete
                {
                    CoachId = coachId,
                    AthleteId = athleteId,
                    AcademyId = command.AcademyId,
                    AssignedBy = ownerUserId,
                    AssignedAt = now
                });
            }

            await _userRepository.AddAsync(user, cancellationToken);
            await _athleteRepository.AddAsync(athlete, cancellationToken);
            await _athleteRepository.AddAssociationAsync(association, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            var loginUrl = string.IsNullOrWhiteSpace(_appOptions.LoginBaseUrl)
                ? _appOptions.FrontendBaseUrl
                : _appOptions.LoginBaseUrl;

            var emailSent = await _emailService.SendAthleteCredentialsAsync(
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
                    "Athlete {AthleteId} for academy {AcademyId} was not created because the welcome email could not be sent.",
                    athleteId,
                    command.AcademyId);
                throw AppException.ServiceUnavailable(
                    "The athlete could not be created because the welcome email could not be sent. Please try again.");
            }

            await _unitOfWork.CommitAsync(cancellationToken);

            var mappedCoaches = await _coachAthleteRepository.GetByAthleteAndAcademyAsync(
                athleteId,
                command.AcademyId,
                cancellationToken);

            _logger.LogInformation(
                "Athlete {AthleteId} ({PublicUserId}) added to academy {AcademyId} by {AssignedBy}",
                athleteId,
                publicUserId,
                command.AcademyId,
                ownerUserId);

            return ApiResponse<CreateAthleteResponse>.Ok(
                AthleteResponseMapper.MapCreated(association, mappedCoaches),
                "Athlete added successfully. Login credentials have been sent to the registered email address.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private async Task<string> GenerateUniquePublicUserIdAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 1; attempt <= MaxPublicUserIdAttempts; attempt++)
        {
            var candidate = await _publicUserIdGenerator.GenerateAsync(
                _appOptions.AthleteUserIdPrefix,
                cancellationToken);

            if (!await _userRepository.PublicUserIdExistsAsync(candidate, cancellationToken))
            {
                return candidate;
            }

            _logger.LogWarning(
                "Public user id collision for prefix {Prefix} on attempt {Attempt}; retrying.",
                _appOptions.AthleteUserIdPrefix,
                attempt);
        }

        throw AppException.ServiceUnavailable(
            "The athlete could not be created because a unique user identifier could not be generated. Please try again.");
    }

    private static AcademyBranch? ResolveBranch(Academy academy, CreateAthleteRequest request)
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

    private static AcademySport ResolvePrimarySport(Academy academy, CreateAthleteRequest request)
    {
        var sport = academy.Sports.FirstOrDefault(s => s.Id == request.PrimarySportId);
        if (sport is null)
        {
            throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException("primarySportId", "The selected primary sport does not belong to this academy.");
        }

        return sport;
    }

    private static AcademySport? ResolveSecondarySport(
        Academy academy,
        CreateAthleteRequest request,
        Guid primarySportId)
    {
        if (request.SecondarySportId is null)
        {
            return null;
        }

        if (request.SecondarySportId == primarySportId)
        {
            throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException("secondarySportId", "Secondary sport must be different from the primary sport.");
        }

        var sport = academy.Sports.FirstOrDefault(s => s.Id == request.SecondarySportId);
        if (sport is null)
        {
            throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException("secondarySportId", "The selected secondary sport does not belong to this academy.");
        }

        return sport;
    }

    private async Task<List<Guid>> ResolveCoachIdsAsync(
        Guid academyId,
        CreateAthleteRequest request,
        CancellationToken cancellationToken)
    {
        if (request.CoachIds.Count == 0)
        {
            return [];
        }

        var academyCoachIds = await _academyRepository.GetAcademyCoachIdsAsync(
            academyId,
            cancellationToken);
        var allowed = academyCoachIds.ToHashSet();

        var result = new List<Guid>(request.CoachIds.Count);
        foreach (var coachId in request.CoachIds.Distinct())
        {
            if (!allowed.Contains(coachId))
            {
                throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException(
                    "coachIds",
                    "The selected coach does not belong to this academy.");
            }

            result.Add(coachId);
        }

        return result;
    }
}
