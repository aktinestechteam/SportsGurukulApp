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

public sealed record CreateAcademyCommand(AcademyRequest Request) : IRequest<ApiResponse<AcademyResponse>>;

public sealed class CreateAcademyCommandValidator : AbstractValidator<CreateAcademyCommand>
{
    public CreateAcademyCommandValidator()
    {
        RuleFor(x => x.Request).SetValidator(new AcademyRequestValidator());
    }
}

public sealed class CreateAcademyCommandHandler : IRequestHandler<CreateAcademyCommand, ApiResponse<AcademyResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CreateAcademyCommandHandler> _logger;

    public CreateAcademyCommandHandler(
        IAcademyRepository academyRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<CreateAcademyCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<AcademyResponse>> Handle(
        CreateAcademyCommand command,
        CancellationToken cancellationToken)
    {
        if (!_currentUserService.IsAuthenticated || _currentUserService.UserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to create an academy.");
        }

        var ownerUserId = _currentUserService.UserId;
        var academy = AcademyFactory.Create(command.Request, ownerUserId);

        await _academyRepository.AddAsync(academy, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Academy {AcademyId} created by user {UserId}", academy.Id, ownerUserId);

        return ApiResponse<AcademyResponse>.Ok(
            AcademyResponseMapper.Map(academy),
            "Academy created successfully.");
    }
}
