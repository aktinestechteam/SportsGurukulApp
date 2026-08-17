using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Academies.Commands;

public sealed record DeleteAcademyCommand(Guid AcademyId) : IRequest<ApiResponse<object>>;

public sealed class DeleteAcademyCommandValidator : AbstractValidator<DeleteAcademyCommand>
{
    public DeleteAcademyCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy identifier is required.");
    }
}

public sealed class DeleteAcademyCommandHandler : IRequestHandler<DeleteAcademyCommand, ApiResponse<object>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<DeleteAcademyCommandHandler> _logger;

    public DeleteAcademyCommandHandler(
        IAcademyRepository academyRepository,
        IAthleteRepository athleteRepository,
        ICoachRepository coachRepository,
        IUserRepository userRepository,
        IRefreshTokenRepository refreshTokenRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<DeleteAcademyCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _athleteRepository = athleteRepository;
        _coachRepository = coachRepository;
        _userRepository = userRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(
        DeleteAcademyCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to delete an academy.");
        }

        var academy = await _academyRepository.GetByIdForOwnerAsync(
            command.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var sportIds = academy.Sports.Select(s => s.Id).ToList();

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            // Sport assignments reference the academy-owned sports with a
            // restrictive FK. Remove them first so the academy's sport rows can
            // be deleted.
            if (sportIds.Count > 0)
            {
                await _athleteRepository.RemoveSportsAsync(sportIds, cancellationToken);
                await _coachRepository.RemoveSportsAsync(sportIds, cancellationToken);
            }

            // Detach every member association so the athlete/coach profiles and
            // the academy child rows below are not blocked by foreign keys.
            await _academyRepository.RemoveAssociationsAsync(command.AcademyId, cancellationToken);

            foreach (var association in academy.AthleteAssociations.ToList())
            {
                if (!await _athleteRepository.HasOtherAssociationsAsync(
                        association.AthleteId,
                        command.AcademyId,
                        cancellationToken))
                {
                    // The athlete account was created for this academy only.
                    // When no other academy references it, remove the full
                    // chain so no orphaned user/athlete records remain.
                    var userId = association.Athlete.UserId;
                    await _refreshTokenRepository.RemoveByUserAsync(userId, cancellationToken);
                    await _userRepository.RemoveRolesAsync(userId, cancellationToken);
                    await _athleteRepository.RemoveAthleteAsync(association.AthleteId, cancellationToken);
                    await _userRepository.DeleteAsync(userId, cancellationToken);
                }
            }

            foreach (var association in academy.CoachAssociations.ToList())
            {
                if (!await _coachRepository.HasOtherAssociationsAsync(
                        association.CoachId,
                        command.AcademyId,
                        cancellationToken))
                {
                    // The coach account was created for this academy only.
                    // When no other academy references it, remove the full
                    // chain so no orphaned user/coach records remain.
                    var userId = association.Coach.UserId;
                    await _refreshTokenRepository.RemoveByUserAsync(userId, cancellationToken);
                    await _userRepository.RemoveRolesAsync(userId, cancellationToken);
                    await _coachRepository.RemoveCoachAsync(association.CoachId, cancellationToken);
                    await _userRepository.DeleteAsync(userId, cancellationToken);
                }
            }

            await _academyRepository.DeleteChildrenAsync(command.AcademyId, cancellationToken);
            await _academyRepository.DeleteByIdAsync(command.AcademyId, cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            _logger.LogInformation("Academy {AcademyId} deleted by user {UserId}", academy.Id, ownerUserId);

            return ApiResponse<object>.OkNoData("Academy deleted successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}
