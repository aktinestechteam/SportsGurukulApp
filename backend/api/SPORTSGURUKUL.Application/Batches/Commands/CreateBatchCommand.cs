using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Batches.Common;
using SPORTSGURUKUL.Application.Batches.DTOs;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Batches.Commands;

public sealed record CreateBatchCommand(Guid AcademyId, BatchRequest Request)
    : IRequest<ApiResponse<BatchResponse>>;

public sealed class CreateBatchCommandValidator : AbstractValidator<CreateBatchCommand>
{
    public CreateBatchCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy identifier is required.");

        RuleFor(x => x.Request)
            .SetValidator(new BatchRequestValidator());
    }
}

public sealed class CreateBatchCommandHandler
    : IRequestHandler<CreateBatchCommand, ApiResponse<BatchResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IBatchRepository _batchRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CreateBatchCommandHandler> _logger;

    public CreateBatchCommandHandler(
        IAcademyRepository academyRepository,
        IBatchRepository batchRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<CreateBatchCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _batchRepository = batchRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<BatchResponse>> Handle(
        CreateBatchCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to create a batch.");
        }

        var academy = await _academyRepository.GetByIdForOwnerAsync(
                command.AcademyId,
                ownerUserId,
                cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var request = command.Request;

        // Validate name uniqueness within the academy
        var existingBatches = await _batchRepository.GetByAcademyAsync(
            command.AcademyId, cancellationToken);
        if (existingBatches.Any(b => b.Name.Equals(request.Name.Trim(), StringComparison.OrdinalIgnoreCase)))
        {
            throw AppException.Conflict($"A batch named \"{request.Name.Trim()}\" already exists in this academy.");
        }

        // Validate SportId belongs to the academy if provided
        if (request.SportId.HasValue)
        {
            var sport = academy.Sports.FirstOrDefault(s => s.Id == request.SportId.Value);
            if (sport is null)
            {
                throw AppException.NotFound("The selected sport does not belong to this academy.");
            }
        }

        // Validate CoachIds belong to the academy
        var academyCoachIds = await _academyRepository.GetAcademyCoachIdsAsync(
            command.AcademyId, cancellationToken);
        var allowedCoachIds = academyCoachIds.ToHashSet();
        foreach (var coachId in request.CoachIds.Distinct())
        {
            if (!allowedCoachIds.Contains(coachId))
            {
                throw AppException.NotFound("One or more selected coaches do not belong to this academy.");
            }
        }

        // Validate AthleteIds belong to the academy
        var academyAthleteIds = await _academyRepository.GetAcademyAthleteIdsAsync(
            command.AcademyId, cancellationToken);
        var allowedAthleteIds = academyAthleteIds.ToHashSet();
        foreach (var athleteId in request.AthleteIds.Distinct())
        {
            if (!allowedAthleteIds.Contains(athleteId))
            {
                throw AppException.NotFound("One or more selected athletes do not belong to this academy.");
            }
        }

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            var now = DateTime.UtcNow;
            var batch = new Batch
            {
                Id = Guid.NewGuid(),
                AcademyId = command.AcademyId,
                Name = request.Name.Trim(),
                Description = request.Description?.Trim(),
                SportId = request.SportId,
                StartDate = request.StartDate.HasValue
                    ? DateTime.SpecifyKind(request.StartDate.Value, DateTimeKind.Utc)
                    : null,
                EndDate = request.EndDate.HasValue
                    ? DateTime.SpecifyKind(request.EndDate.Value, DateTimeKind.Utc)
                    : null,
                CreatedAt = now,
                UpdatedAt = now,
            };

            foreach (var slot in request.Slots)
            {
                batch.Slots.Add(new BatchScheduleSlot
                {
                    Id = Guid.NewGuid(),
                    BatchId = batch.Id,
                    StartTime = slot.StartTime,
                    EndTime = slot.EndTime,
                    Location = slot.Location?.Trim(),
                    CreatedAt = now,
                });
            }

            foreach (var coachId in request.CoachIds.Distinct())
            {
                batch.CoachAssociations.Add(new BatchCoach
                {
                    BatchId = batch.Id,
                    CoachId = coachId,
                    AssignedAt = now,
                });
            }

            foreach (var athleteId in request.AthleteIds.Distinct())
            {
                batch.AthleteAssociations.Add(new BatchAthlete
                {
                    BatchId = batch.Id,
                    AthleteId = athleteId,
                    AssignedAt = now,
                });
            }

            await _batchRepository.AddAsync(batch, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            // Reload with navigations for the response
            var reloaded = await _batchRepository.GetByIdForOwnerAsync(
                batch.Id, ownerUserId, cancellationToken);

            _logger.LogInformation(
                "Batch {BatchId} ({BatchName}) created in academy {AcademyId} by user {UserId}",
                batch.Id, batch.Name, command.AcademyId, ownerUserId);

            return ApiResponse<BatchResponse>.Ok(
                BatchResponseMapper.Map(reloaded!),
                "Batch created successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}
