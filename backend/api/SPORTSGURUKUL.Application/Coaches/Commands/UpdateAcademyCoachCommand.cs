using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Common;
using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Coaches.Commands;

public sealed record UpdateAcademyCoachCommand(
    Guid AcademyId,
    Guid CoachId,
    CreateCoachRequest Request) : IRequest<ApiResponse<CoachResponse>>;

public sealed class UpdateAcademyCoachCommandValidator : AbstractValidator<UpdateAcademyCoachCommand>
{
    public UpdateAcademyCoachCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy is required.");

        RuleFor(x => x.CoachId)
            .NotEmpty().WithMessage("Coach is required.");

        RuleFor(x => x.Request)
            .SetValidator(new CreateCoachRequestValidator());
    }
}

public sealed class UpdateAcademyCoachCommandHandler
    : IRequestHandler<UpdateAcademyCoachCommand, ApiResponse<CoachResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IUserRepository _userRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UpdateAcademyCoachCommandHandler> _logger;

    public UpdateAcademyCoachCommandHandler(
        IAcademyRepository academyRepository,
        IUserRepository userRepository,
        ICoachRepository coachRepository,
        ICoachAthleteRepository coachAthleteRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<UpdateAcademyCoachCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _userRepository = userRepository;
        _coachRepository = coachRepository;
        _coachAthleteRepository = coachAthleteRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<CoachResponse>> Handle(
        UpdateAcademyCoachCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to update a coach.");
        }

        var academy = await _academyRepository.GetByIdForOwnerAsync(
            command.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var association = await _coachRepository.GetByAcademyAndCoachAsync(
            command.AcademyId,
            command.CoachId,
            cancellationToken)
            ?? throw AppException.NotFound("Coach not found.");

        var request = command.Request;
        var normalizedEmail = request.Email.Trim().ToUpperInvariant();
        var normalizedMobile = request.MobileNumber.Trim().ToUpperInvariant();

        if (await _userRepository.EmailExistsExcludingAsync(normalizedEmail, association.Coach.UserId, cancellationToken))
        {
            throw AppException.Conflict("This email is already registered with Sports Gurukul.");
        }

        if (await _userRepository.MobileNumberExistsExcludingAsync(normalizedMobile, association.Coach.UserId, cancellationToken))
        {
            throw AppException.Conflict("This mobile number is already registered with Sports Gurukul.");
        }

        var branch = ResolveBranch(academy, request);
        var sports = ResolveSports(academy, request);
        var athleteIds = await ResolveAthleteIdsAsync(command.AcademyId, request, cancellationToken);

        var user = association.Coach.User;
        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Email = request.Email.Trim();
        user.NormalizedEmail = normalizedEmail;
        user.MobileNumber = request.MobileNumber.Trim();
        user.NormalizedMobileNumber = normalizedMobile;
        user.UpdatedAt = DateTime.UtcNow;

        association.Coach.Touch();
        association.BranchId = branch?.Id;
        association.Branch = branch;

        await _coachRepository.ReplaceSportsAsync(association.Coach, sports, cancellationToken);
        await _coachAthleteRepository.ReplaceCoachMappingsAsync(
            command.CoachId,
            command.AcademyId,
            athleteIds,
            ownerUserId,
            cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var saved = await _coachRepository.GetByAcademyAndCoachAsNoTrackingAsync(
            command.AcademyId,
            command.CoachId,
            cancellationToken)
            ?? throw AppException.NotFound("Coach not found.");

        var mappedAthletes = await _coachAthleteRepository.GetByCoachAndAcademyAsync(
            command.CoachId,
            command.AcademyId,
            cancellationToken);

        _logger.LogInformation(
            "Coach {CoachId} updated for academy {AcademyId} by user {UserId}",
            command.CoachId,
            command.AcademyId,
            ownerUserId);

        return ApiResponse<CoachResponse>.Ok(
            CoachResponseMapper.Map(saved, mappedAthletes),
            "Coach updated successfully.");
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
}
