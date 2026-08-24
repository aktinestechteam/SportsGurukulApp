using FluentValidation;
using MediatR;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Application.Batches.Commands;

public sealed record DeleteBatchCommand(Guid AcademyId, Guid BatchId)
    : IRequest<ApiResponse<object>>;

public sealed class DeleteBatchCommandValidator : AbstractValidator<DeleteBatchCommand>
{
    public DeleteBatchCommandValidator()
    {
        RuleFor(x => x.AcademyId)
            .NotEmpty().WithMessage("Academy identifier is required.");

        RuleFor(x => x.BatchId)
            .NotEmpty().WithMessage("Batch identifier is required.");
    }
}

public sealed class DeleteBatchCommandHandler
    : IRequestHandler<DeleteBatchCommand, ApiResponse<object>>
{
    private readonly IBatchRepository _batchRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<DeleteBatchCommandHandler> _logger;

    public DeleteBatchCommandHandler(
        IBatchRepository batchRepository,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        ILogger<DeleteBatchCommandHandler> logger)
    {
        _batchRepository = batchRepository;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<ApiResponse<object>> Handle(
        DeleteBatchCommand command,
        CancellationToken cancellationToken)
    {
        var ownerUserId = _currentUserService.UserId;
        if (ownerUserId == Guid.Empty)
        {
            throw AppException.Unauthorized("You must be signed in to delete a batch.");
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

        await _unitOfWork.BeginTransactionAsync(cancellationToken);
        try
        {
            await _batchRepository.DeleteChildrenAsync(command.BatchId, cancellationToken);
            await _batchRepository.DeleteByIdAsync(command.BatchId, cancellationToken);
            await _unitOfWork.CommitAsync(cancellationToken);

            _logger.LogInformation(
                "Batch {BatchId} ({BatchName}) deleted from academy {AcademyId} by user {UserId}",
                batch.Id, batch.Name, command.AcademyId, ownerUserId);

            return ApiResponse<object>.OkNoData("Batch deleted successfully.");
        }
        catch
        {
            await _unitOfWork.RollbackAsync(cancellationToken);
            throw;
        }
    }
}
