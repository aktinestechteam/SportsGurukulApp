using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Common;
using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;

namespace SPORTSGURUKUL.Application.Academies.Commands;

public sealed record UpdateAcademyCommand(
    Guid AcademyId,
    AcademyRequest Request) : IRequest<ApiResponse<AcademyResponse>>;

public sealed class UpdateAcademyCommandValidator : AbstractValidator<UpdateAcademyCommand>
{
    public UpdateAcademyCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy identifier is required.");

        RuleFor(x => x.Request).SetValidator(new AcademyRequestValidator());
    }
}

public sealed class UpdateAcademyCommandHandler : IRequestHandler<UpdateAcademyCommand, ApiResponse<AcademyResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UpdateAcademyCommandHandler> _logger;

    public UpdateAcademyCommandHandler(
        IAcademyRepository academyRepository,
        ICoachRepository coachRepository,
        IAthleteRepository athleteRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<UpdateAcademyCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _coachRepository = coachRepository;
        _athleteRepository = athleteRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<AcademyResponse>> Handle(
        UpdateAcademyCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to update an academy.");
        }

        var academy = await _academyRepository.GetByIdForOwnerAsync(
            command.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        // Capture existing sport assignments before the factory clears the
        // sports collection. AcademySports are referenced by CoachSports and
        // AthleteSports with a restrictive FK, so we must remove those
        // dependent rows first and rebuild them afterwards.
        var oldSportIdByName = academy.Sports
            .ToDictionary(s => s.Name, s => s.Id);

        var oldCoachSports = academy.CoachAssociations
            .SelectMany(ca => ca.Coach.Sports)
            .Where(cs => oldSportIdByName.ContainsValue(cs.SportId))
            .Select(cs => new { cs.CoachId, SportName = cs.Sport.Name, cs.Specialization })
            .ToList();

        var oldAthleteSports = academy.AthleteAssociations
            .SelectMany(aa => aa.Athlete.Sports)
            .Where(as2 => oldSportIdByName.ContainsValue(as2.SportId))
            .Select(as2 => new { as2.AthleteId, SportName = as2.Sport.Name, as2.IsPrimary })
            .ToList();

        var oldSportIds = oldSportIdByName.Values.ToList();

        // Remove CoachSports and AthleteSports that reference the old
        // academy sport IDs so the restrictive FK doesn't block the delete.
        if (oldSportIds.Count > 0)
        {
            await _coachRepository.RemoveSportsAsync(oldSportIds, cancellationToken);
            await _athleteRepository.RemoveSportsAsync(oldSportIds, cancellationToken);
        }

        // AcademyFactory.Update clears and recreates the Sports collection
        // with new GUIDs, which triggers delete-old + insert-new on save.
        AcademyFactory.Update(academy, command.Request);

        await _academyRepository.UpdateAsync(academy, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Rebuild coach and athlete sport assignments using the new sport IDs.
        var newSportIdByName = academy.Sports
            .ToDictionary(s => s.Name, s => s.Id);

        foreach (var cs in oldCoachSports)
        {
            if (newSportIdByName.TryGetValue(cs.SportName, out var newSportId))
            {
                await _coachRepository.AddSportAsync(
                    cs.CoachId, newSportId, cs.Specialization, cancellationToken);
            }
        }

        foreach (var as2 in oldAthleteSports)
        {
            if (newSportIdByName.TryGetValue(as2.SportName, out var newSportId))
            {
                await _athleteRepository.AddSportAsync(
                    as2.AthleteId, newSportId, as2.IsPrimary, cancellationToken);
            }
        }

        if (oldSportIds.Count > 0)
        {
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        _logger.LogInformation("Academy {AcademyId} updated by user {UserId}", academy.Id, ownerUserId);

        return ApiResponse<AcademyResponse>.Ok(
            AcademyResponseMapper.Map(academy),
            "Academy updated successfully.");
    }
}
