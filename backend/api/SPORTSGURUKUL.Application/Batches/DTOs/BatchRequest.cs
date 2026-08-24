using FluentValidation;

namespace SPORTSGURUKUL.Application.Batches.DTOs;

public sealed class BatchRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? SportId { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public List<BatchScheduleSlotRequest> Slots { get; set; } = [];
    public List<Guid> CoachIds { get; set; } = [];
    public List<Guid> AthleteIds { get; set; } = [];
}

public sealed class BatchScheduleSlotRequest
{
    public DayOfWeek DayOfWeek { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public string? Location { get; set; }
}

public sealed class BatchRequestValidator : AbstractValidator<BatchRequest>
{
    public BatchRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Batch name is required.")
            .MaximumLength(200).WithMessage("Batch name must not exceed 200 characters.");

        RuleFor(x => x.Description)
            .MaximumLength(2000).WithMessage("Description must not exceed 2000 characters.");

        RuleForEach(x => x.Slots).SetValidator(new BatchScheduleSlotRequestValidator());
    }
}

public sealed class BatchScheduleSlotRequestValidator : AbstractValidator<BatchScheduleSlotRequest>
{
    public BatchScheduleSlotRequestValidator()
    {
        RuleFor(x => x.StartTime)
            .LessThan(x => x.EndTime).WithMessage("Start time must be before end time.");

        RuleFor(x => x.Location)
            .MaximumLength(200).WithMessage("Location must not exceed 200 characters.");
    }
}
