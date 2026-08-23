using FluentValidation;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Coaches.DTOs;

namespace SPORTSGURUKUL.Application.Coaches.Common;

public sealed class CreateCoachRequestValidator : AbstractValidator<CreateCoachRequest>
{
    public CreateCoachRequestValidator()
    {
        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("First name is required.")
            .MaximumLength(100).WithMessage("First name must not exceed 100 characters.");

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage("Last name is required.")
            .MaximumLength(100).WithMessage("Last name must not exceed 100 characters.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Invalid email address.")
            .MaximumLength(256).WithMessage("Email must not exceed 256 characters.");

        RuleFor(x => x.MobileNumber)
            .NotEmpty().WithMessage("Mobile number is required.")
            .Matches(PasswordPolicy.MobilePattern).WithMessage(PasswordPolicy.MobileMessage);

        RuleFor(x => x.Sports)
            .NotEmpty().WithMessage("At least one sport must be selected.")
            .Must(x => x.Count <= 50).WithMessage("Too many sports selected.");

        RuleForEach(x => x.Sports)
            .SetValidator(new CoachSportAssignmentRequestValidator());
    }
}

public sealed class CoachSportAssignmentRequestValidator : AbstractValidator<CoachSportAssignmentRequest>
{
    public CoachSportAssignmentRequestValidator()
    {
        RuleFor(x => x.SportId)
            .NotEmpty().WithMessage("A valid sport must be selected.");

        RuleFor(x => x.Specialization)
            .MaximumLength(200).WithMessage("Specialization must not exceed 200 characters.");
    }
}
