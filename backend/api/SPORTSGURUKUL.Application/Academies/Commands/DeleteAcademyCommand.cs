using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Application.Academies.Interfaces;
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
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<DeleteAcademyCommandHandler> _logger;

    public DeleteAcademyCommandHandler(
        IAcademyRepository academyRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<DeleteAcademyCommandHandler> logger)
    {
        _academyRepository = academyRepository;
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

        await _academyRepository.DeleteAsync(academy, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Academy {AcademyId} deleted by user {UserId}", academy.Id, ownerUserId);

        return ApiResponse<object>.OkNoData("Academy deleted successfully.");
    }
}
