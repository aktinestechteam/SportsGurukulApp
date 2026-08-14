using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Common;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
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
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UpdateAcademyAthleteCommandHandler> _logger;

    public UpdateAcademyAthleteCommandHandler(
        IAcademyRepository academyRepository,
        IUserRepository userRepository,
        IAthleteRepository athleteRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<UpdateAcademyAthleteCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _userRepository = userRepository;
        _athleteRepository = athleteRepository;
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
        var primarySport = ResolvePrimarySport(academy, request);
        var secondarySport = ResolveSecondarySport(academy, request, primarySport.Id);

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
            BuildSports(athlete.Id, primarySport, secondarySport, now),
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var saved = await _athleteRepository.GetByAcademyAndAthleteAsNoTrackingAsync(
            command.AcademyId,
            command.AthleteId,
            cancellationToken)
            ?? throw AppException.NotFound("Athlete not found.");

        _logger.LogInformation(
            "Athlete {AthleteId} updated for academy {AcademyId} by user {UserId}",
            command.AthleteId,
            command.AcademyId,
            ownerUserId);

        return ApiResponse<CreateAthleteResponse>.Ok(
            AthleteResponseMapper.MapCreated(saved),
            "Athlete updated successfully.");
    }

    private static List<AthleteSport> BuildSports(
        Guid athleteId,
        AcademySport primarySport,
        AcademySport? secondarySport,
        DateTime now)
    {
        var sports = new List<AthleteSport>
        {
            new()
            {
                AthleteId = athleteId,
                SportId = primarySport.Id,
                IsPrimary = true,
                Sport = primarySport,
                CreatedAt = now
            }
        };

        if (secondarySport is not null)
        {
            sports.Add(new AthleteSport
            {
                AthleteId = athleteId,
                SportId = secondarySport.Id,
                IsPrimary = false,
                Sport = secondarySport,
                CreatedAt = now
            });
        }

        return sports;
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
}
