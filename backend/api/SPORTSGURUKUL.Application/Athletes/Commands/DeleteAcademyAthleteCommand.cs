using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Athletes.Commands;

public sealed record DeleteAcademyAthleteCommand(
    Guid AcademyId,
    Guid AthleteId) : IRequest<ApiResponse<object>>;

public sealed class DeleteAcademyAthleteCommandValidator : AbstractValidator<DeleteAcademyAthleteCommand>
{
    public DeleteAcademyAthleteCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy is required.");

        RuleFor(x => x.AthleteId)
            .NotEmpty().WithMessage("Athlete is required.");
    }
}

public sealed class DeleteAcademyAthleteCommandHandler
    : IRequestHandler<DeleteAcademyAthleteCommand, ApiResponse<object>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly IAthleteRepository _athleteRepository;
    private readonly ICoachAthleteRepository _coachAthleteRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<DeleteAcademyAthleteCommandHandler> _logger;

    public DeleteAcademyAthleteCommandHandler(
        IAcademyRepository academyRepository,
        IUserRepository userRepository,
        IRefreshTokenRepository refreshTokenRepository,
        IAthleteRepository athleteRepository,
        ICoachAthleteRepository coachAthleteRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<DeleteAcademyAthleteCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _userRepository = userRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _athleteRepository = athleteRepository;
        _coachAthleteRepository = coachAthleteRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(
        DeleteAcademyAthleteCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to remove an athlete.");
        }

        _ = await _academyRepository.GetByIdForOwnerAsync(
            command.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var association = await _athleteRepository.GetByAcademyAndAthleteAsync(
            command.AcademyId,
            command.AthleteId,
            cancellationToken)
            ?? throw AppException.NotFound("Athlete not found.");

        var athleteId = association.AthleteId;
        var userId = association.Athlete.UserId;

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            await _coachAthleteRepository.RemoveByAthleteAsync(
                athleteId,
                command.AcademyId,
                cancellationToken);

            await _athleteRepository.RemoveAssociationAsync(command.AcademyId, athleteId, cancellationToken);

            if (!await _athleteRepository.HasOtherAssociationsAsync(athleteId, command.AcademyId, cancellationToken))
            {
                // The athlete account was created for this academy only. When no
                // other academy references it, remove the full chain so no
                // orphaned user/athlete records remain.
                await _refreshTokenRepository.RemoveByUserAsync(userId, cancellationToken);
                await _userRepository.RemoveRolesAsync(userId, cancellationToken);
                await _athleteRepository.RemoveAthleteAsync(athleteId, cancellationToken);
                await _userRepository.DeleteAsync(userId, cancellationToken);
            }

            await _unitOfWork.CommitAsync(cancellationToken);

            _logger.LogInformation(
                "Athlete {AthleteId} removed from academy {AcademyId} by user {UserId}",
                athleteId,
                command.AcademyId,
                ownerUserId);

            return ApiResponse<object>.OkNoData("Athlete removed from the academy successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}
