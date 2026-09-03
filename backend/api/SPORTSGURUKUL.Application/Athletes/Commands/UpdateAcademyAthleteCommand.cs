using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Common;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Athletes.Commands;

public sealed record UpdateAcademyAthleteCommand(
    Guid AcademyId,
    Guid AthleteId,
    CreateAthleteRequest Request) : IRequest<ApiResponse<CreateAthleteResponse>>;

public sealed class UpdateAcademyAthleteCommandValidator : AbstractValidator<UpdateAcademyAthleteCommand>
{
    public UpdateAcademyAthleteCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy is required.");

        RuleFor(x => x.AthleteId)
            .NotEmpty().WithMessage("Athlete is required.");

        RuleFor(x => x.Request)
            .SetValidator(new CreateAthleteRequestValidator());
    }
}

public sealed class UpdateAcademyAthleteCommandHandler
    : IRequestHandler<UpdateAcademyAthleteCommand, ApiResponse<CreateAthleteResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IUserRepository _userRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UpdateAcademyAthleteCommandHandler> _logger;

    public UpdateAcademyAthleteCommandHandler(
        IAcademyRepository academyRepository,
        IUserRepository userRepository,
        IAthleteRepository athleteRepository,
        ICoachAthleteRepository coachAthleteRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<UpdateAcademyAthleteCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _userRepository = userRepository;
        _athleteRepository = athleteRepository;
        _coachAthleteRepository = coachAthleteRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<CreateAthleteResponse>> Handle(
        UpdateAcademyAthleteCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to update an athlete.");
        }

        var academy = await _academyRepository.GetByIdForOwnerAsync(
            command.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var association = await _athleteRepository.GetByAcademyAndAthleteAsync(
            command.AcademyId,
            command.AthleteId,
            cancellationToken)
            ?? throw AppException.NotFound("Athlete not found.");

        var request = command.Request;
        var normalizedEmail = request.Email.Trim().ToUpperInvariant();
        var normalizedMobile = request.MobileNumber.Trim().ToUpperInvariant();

        if (await _userRepository.EmailExistsExcludingAsync(normalizedEmail, association.Athlete.UserId, cancellationToken))
        {
            throw AppException.Conflict("This email is already registered with Sports Gurukul.");
        }

        if (await _userRepository.MobileNumberExistsExcludingAsync(normalizedMobile, association.Athlete.UserId, cancellationToken))
        {
            throw AppException.Conflict("This mobile number is already registered with Sports Gurukul.");
        }

        var branch = ResolveBranch(academy, request);
        var sports = ResolveSports(academy, request);
        var coachAssignments = await ResolveCoachAssignmentsAsync(
            command.AcademyId,
            request,
            cancellationToken);

        // Date-only payloads (e.g. "2011-01-01") deserialize to a DateTime
        // with Kind=Unspecified, which Npgsql rejects for timestamptz
        // columns. Normalize to UTC midnight before persisting.
        var dateOfBirth = DateTime.SpecifyKind(request.DateOfBirth.Date, DateTimeKind.Utc);
        var now = DateTime.UtcNow;

        var user = association.Athlete.User;
        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Email = request.Email.Trim();
        user.NormalizedEmail = normalizedEmail;
        user.MobileNumber = request.MobileNumber.Trim();
        user.NormalizedMobileNumber = normalizedMobile;
        user.UpdatedAt = now;

        var athlete = association.Athlete;
        athlete.DateOfBirth = dateOfBirth;
        athlete.Gender = request.Gender ?? AthleteGender.Male;
        athlete.Address = request.Address?.Trim();
        athlete.EmergencyContact = request.EmergencyContact?.Trim();
        athlete.AgeGroup = AgeGroupCalculator.CalculateAgeGroup(dateOfBirth);
        athlete.Touch();

        association.BranchId = branch?.Id;
        association.Branch = branch;

        await _athleteRepository.ReplaceSportsAsync(
            athlete,
            BuildSports(athlete.Id, sports, now),
            cancellationToken);

        await _coachAthleteRepository.ReplaceAthleteMappingsAsync(
            command.AthleteId,
            command.AcademyId,
            coachAssignments,
            ownerUserId,
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var saved = await _athleteRepository.GetByAcademyAndAthleteAsNoTrackingAsync(
            command.AcademyId,
            command.AthleteId,
            cancellationToken)
            ?? throw AppException.NotFound("Athlete not found.");

        var mappedCoaches = await _coachAthleteRepository.GetByAthleteAndAcademyAsync(
            command.AthleteId,
            command.AcademyId,
            cancellationToken);

        _logger.LogInformation(
            "Athlete {AthleteId} updated for academy {AcademyId} by user {UserId}",
            command.AthleteId,
            command.AcademyId,
            ownerUserId);

        return ApiResponse<CreateAthleteResponse>.Ok(
            AthleteResponseMapper.MapCreated(saved, mappedCoaches),
            "Athlete updated successfully.");
    }

    private async Task<List<SportCoachAssignment>> ResolveCoachAssignmentsAsync(
        Guid academyId,
        CreateAthleteRequest request,
        CancellationToken cancellationToken)
    {
        if (request.CoachAssignments.Count == 0)
        {
            return [];
        }

        var academyCoachIds = await _academyRepository.GetAcademyCoachIdsAsync(
            academyId,
            cancellationToken);
        var allowed = academyCoachIds.ToHashSet();

        var result = new List<SportCoachAssignment>(request.CoachAssignments.Count);
        foreach (var assignment in request.CoachAssignments)
        {
            if (assignment.CoachIds.Count == 0)
            {
                continue;
            }

            var resolved = new List<Guid>(assignment.CoachIds.Count);
            foreach (var coachId in assignment.CoachIds.Distinct())
            {
                if (!allowed.Contains(coachId))
                {
                    throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException(
                        "coachAssignments",
                        "The selected coach does not belong to this academy.");
                }

                resolved.Add(coachId);
            }

            result.Add(new SportCoachAssignment
            {
                SportId = assignment.SportId,
                CoachIds = resolved
            });
        }

        return result;
    }

    private static List<AthleteSport> BuildSports(
        Guid athleteId,
        List<AcademySport> sports,
        DateTime now)
    {
        return sports.Select(sport => new AthleteSport
        {
            AthleteId = athleteId,
            SportId = sport.Id,
            IsPrimary = false,
            Sport = sport,
            CreatedAt = now
        }).ToList();
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

    private static List<AcademySport> ResolveSports(Academy academy, CreateAthleteRequest request)
    {
        if (request.SportIds.Count == 0)
        {
            throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException(
                "sportIds", "At least one sport must be selected.");
        }

        if (request.SportIds.Count != request.SportIds.Distinct().Count())
        {
            throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException(
                "sportIds", "Duplicate sports are not allowed.");
        }

        var resolved = new List<AcademySport>();
        foreach (var sportId in request.SportIds)
        {
            var sport = academy.Sports.FirstOrDefault(s => s.Id == sportId);
            if (sport is null)
            {
                throw new SPORTSGURUKUL.Application.Common.Exceptions.ValidationException(
                    "sportIds",
                    $"The selected sport {sportId} does not belong to this academy.");
            }

            resolved.Add(sport);
        }

        return resolved;
    }
}
