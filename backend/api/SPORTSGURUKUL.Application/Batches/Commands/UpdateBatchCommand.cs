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

public sealed record UpdateBatchCommand(Guid AcademyId, Guid BatchId, BatchRequest Request)
    : IRequest<ApiResponse<BatchResponse>>;

public sealed class UpdateBatchCommandValidator : AbstractValidator<UpdateBatchCommand>
{
    public UpdateBatchCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy identifier is required.");

        RuleFor(x => x.BatchId)
            .NotEmpty().WithMessage("Batch identifier is required.");

        RuleFor(x => x.Request)
            .SetValidator(new BatchRequestValidator());
    }
}

public sealed class UpdateBatchCommandHandler
    : IRequestHandler<UpdateBatchCommand, ApiResponse<BatchResponse>>
{
    private readonly IAcademyRepository _academyRepository;
    private readonly IBatchRepository _batchRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UpdateBatchCommandHandler> _logger;

    public UpdateBatchCommandHandler(
        IAcademyRepository academyRepository,
        IBatchRepository batchRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<UpdateBatchCommandHandler> logger)
    {
        _academyRepository = academyRepository;
        _batchRepository = batchRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<BatchResponse>> Handle(
        UpdateBatchCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to update a batch.");
        }

        var batch = await _batchRepository.GetByIdForOwnerAsync(
                command.BatchId,
                ownerUserId,
                cancellationToken)
            ?? throw AppException.NotFound("Batch not found.");

        if (batch.AcademyId != command.AcademyId)
        {
            throw AppException.NotFound("Batch not found in this academy.");
        }

        var academy = await _academyRepository.GetByIdForOwnerAsync(
                command.AcademyId,
                ownerUserId,
                cancellationToken)
            ?? throw AppException.NotFound("Academy not found.");

        var request = command.Request;

        var existingBatches = await _batchRepository.GetByAcademyAsync(
            command.AcademyId, cancellationToken);
        if (existingBatches.Any(b => b.Id != command.BatchId &&
            b.Name.Equals(request.Name.Trim(), StringComparison.OrdinalIgnoreCase)))
        {
            throw AppException.Conflict(
                $"A batch named \"{request.Name.Trim()}\" already exists in this academy.");
        }

        if (request.SportId.HasValue)
        {
            var sport = academy.Sports.FirstOrDefault(s => s.Id == request.SportId.Value);
            if (sport is null)
            {
                throw AppException.NotFound("The selected sport does not belong to this academy.");
            }
        }

        var academyCoachIds = await _academyRepository.GetAcademyCoachIdsAsync(
            command.AcademyId, cancellationToken);
        var allowedCoachIds = academyCoachIds.ToHashSet();
        foreach (var coachId in request.CoachIds.Distinct())
        {
            if (!allowedCoachIds.Contains(coachId))
            {
                throw AppException.NotFound(
                    "One or more selected coaches do not belong to this academy.");
            }
        }

        var academyAthleteIds = await _academyRepository.GetAcademyAthleteIdsAsync(
            command.AcademyId, cancellationToken);
        var allowedAthleteIds = academyAthleteIds.ToHashSet();
        foreach (var athleteId in request.AthleteIds.Distinct())
        {
            if (!allowedAthleteIds.Contains(athleteId))
            {
                throw AppException.NotFound(
                    "One or more selected athletes do not belong to this academy.");
            }
        }

        var batchId = command.BatchId;
        var name = request.Name.Trim();
        var description = request.Description?.Trim();
        var sportId = request.SportId;
        var startDate = request.StartDate.HasValue
            ? DateTime.SpecifyKind(request.StartDate.Value, DateTimeKind.Utc)
            : (DateTime?)null;
        var endDate = request.EndDate.HasValue
            ? DateTime.SpecifyKind(request.EndDate.Value, DateTimeKind.Utc)
            : (DateTime?)null;
        var now = DateTime.UtcNow;

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            await _unitOfWork.ExecuteSqlRawAsync(
                "DELETE FROM \"BatchScheduleSlots\" WHERE \"BatchId\" = {0}",
                new object[] { batchId }, cancellationToken);
            await _unitOfWork.ExecuteSqlRawAsync(
                "DELETE FROM \"BatchCoaches\" WHERE \"BatchId\" = {0}",
                new object[] { batchId }, cancellationToken);
            await _unitOfWork.ExecuteSqlRawAsync(
                "DELETE FROM \"BatchAthletes\" WHERE \"BatchId\" = {0}",
                new object[] { batchId }, cancellationToken);

            await _unitOfWork.ExecuteSqlRawAsync(
                "UPDATE \"Batches\" SET \"Name\" = {0}, \"Description\" = {1}, \"SportId\" = {2}, \"StartDate\" = {3}, \"EndDate\" = {4}, \"UpdatedAt\" = {5} WHERE \"Id\" = {6}",
                new object[] { name, description, sportId, startDate, endDate, now, batchId }, cancellationToken);

            foreach (var slot in request.Slots)
            {
                var slotId = Guid.NewGuid();
                await _unitOfWork.ExecuteSqlRawAsync(
                    "INSERT INTO \"BatchScheduleSlots\" (\"Id\", \"BatchId\", \"StartTime\", \"EndTime\", \"Location\", \"CreatedAt\") VALUES ({0}, {1}, {2}, {3}, {4}, {5})",
                    new object[] { slotId, batchId, slot.StartTime, slot.EndTime, slot.Location?.Trim(), now }, cancellationToken);
            }

            foreach (var coachId in request.CoachIds.Distinct())
            {
                await _unitOfWork.ExecuteSqlRawAsync(
                    "INSERT INTO \"BatchCoaches\" (\"BatchId\", \"CoachId\", \"AssignedAt\") VALUES ({0}, {1}, {2})",
                    new object[] { batchId, coachId, now }, cancellationToken);
            }

            foreach (var athleteId in request.AthleteIds.Distinct())
            {
                await _unitOfWork.ExecuteSqlRawAsync(
                    "INSERT INTO \"BatchAthletes\" (\"BatchId\", \"AthleteId\", \"AssignedAt\") VALUES ({0}, {1}, {2})",
                    new object[] { batchId, athleteId, now }, cancellationToken);
            }

            await _unitOfWork.CommitAsync(cancellationToken);

            _batchRepository.ClearTracker();
            var reloaded = await _batchRepository.GetByIdForOwnerAsync(
                batch.Id, ownerUserId, cancellationToken);

            _logger.LogInformation(
                "Batch {BatchId} ({BatchName}) updated in academy {AcademyId} by user {UserId}",
                batch.Id, batch.Name, command.AcademyId, ownerUserId);

            return ApiResponse<BatchResponse>.Ok(
                BatchResponseMapper.Map(reloaded!),
                "Batch updated successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}
