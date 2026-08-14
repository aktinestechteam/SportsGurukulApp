using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Coaches.Commands;

public sealed record DeleteAcademyCoachCommand(
    Guid AcademyId,
    Guid CoachId) : IRequest<ApiResponse<object>>;

public sealed class DeleteAcademyCoachCommandValidator : AbstractValidator<DeleteAcademyCoachCommand>
{
    public DeleteAcademyCoachCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy is required.");

        RuleFor(x => x.CoachId)
            .NotEmpty().WithMessage("Coach is required.");
    }
}

public sealed class DeleteAcademyCoachCommandHandler
    : IRequestHandler<DeleteAcademyCoachCommand, ApiResponse<object>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRefreshTokenRepository _refreshTokenRepository;
    private readonly ICoachRepository _coachRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<DeleteAcademyCoachCommandHandler> _logger;

    public DeleteAcademyCoachCommandHandler(
        IAcademyRepository academyRepository,
        IUserRepository userRepository,
        IRefreshTokenRepository refreshTokenRepository,
        ICoachRepository coachRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<DeleteAcademyCoachCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _userRepository = userRepository;
        _refreshTokenRepository = refreshTokenRepository;
        _coachRepository = coachRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(
        DeleteAcademyCoachCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to remove a coach.");
        }

        _ = await _academyRepository.GetByIdForOwnerAsync(
            command.AcademyId,
            ownerUserId,
            cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var association = await _coachRepository.GetByAcademyAndCoachAsync(
            command.AcademyId,
            command.CoachId,
            cancellationToken)
            ?? throw AppException.NotFound("Coach not found.");

        var coachId = association.CoachId;
        var userId = association.Coach.UserId;

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            await _coachRepository.RemoveAssociationAsync(command.AcademyId, coachId, cancellationToken);

            if (!await _coachRepository.HasOtherAssociationsAsync(coachId, command.AcademyId, cancellationToken))
            {
                // The coach account was created for this academy only. When no
                // other academy references it, remove the full chain so no
                // orphaned user/coach records remain.
                await _refreshTokenRepository.RemoveByUserAsync(userId, cancellationToken);
                await _userRepository.RemoveRolesAsync(userId, cancellationToken);
                await _coachRepository.RemoveCoachAsync(coachId, cancellationToken);
                await _userRepository.DeleteAsync(userId, cancellationToken);
            }

            await _unitOfWork.CommitAsync(cancellationToken);

            _logger.LogInformation(
                "Coach {CoachId} removed from academy {AcademyId} by user {UserId}",
                coachId,
                command.AcademyId,
                ownerUserId);

            return ApiResponse<object>.OkNoData("Coach removed from the academy successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}
