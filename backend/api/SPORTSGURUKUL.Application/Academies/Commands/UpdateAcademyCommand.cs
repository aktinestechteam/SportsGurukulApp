using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Common;
using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

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
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UpdateAcademyCommandHandler> _logger;

    public UpdateAcademyCommandHandler(
        IAcademyRepository academyRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<UpdateAcademyCommandHandler> logger)
    {
        _academyRepository = academyRepository;
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

        AcademyFactory.Update(academy, command.Request);

        await _academyRepository.UpdateAsync(academy, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Academy {AcademyId} updated by user {UserId}", academy.Id, ownerUserId);

        return ApiResponse<AcademyResponse>.Ok(
            AcademyResponseMapper.Map(academy),
            "Academy updated successfully.");
    }
}
