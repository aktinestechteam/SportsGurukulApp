using FluentValidation;
using SPORTSGURUKUL.Application.Academies.DTOs;

namespace SPORTSGURUKUL.Application.Academies.Common;

public sealed class AcademyRequestValidator : AbstractValidator<AcademyRequest>
{
    public AcademyRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Academy name is required.")
            .MaximumLength(200).WithMessage("Academy name must not exceed 200 characters.");

        RuleFor(x => x.Profile)
            .MaximumLength(2000).WithMessage("Profile must not exceed 2000 characters.");

        RuleFor(x => x.ContactEmail)
            .EmailAddress().WithMessage("Invalid contact email address.")
            .MaximumLength(256).WithMessage("Contact email must not exceed 256 characters.")
            .When(x => !string.IsNullOrWhiteSpace(x.ContactEmail));

        RuleFor(x => x.ContactPhone)
            .MaximumLength(30).WithMessage("Contact phone must not exceed 30 characters.");

        RuleFor(x => x.Address)
            .MaximumLength(300).WithMessage("Address must not exceed 300 characters.");

        RuleFor(x => x.City)
            .MaximumLength(100).WithMessage("City must not exceed 100 characters.");

        RuleFor(x => x.State)
            .MaximumLength(100).WithMessage("State must not exceed 100 characters.");

        RuleFor(x => x.Country)
            .MaximumLength(100).WithMessage("Country must not exceed 100 characters.");

        RuleFor(x => x.PostalCode)
            .MaximumLength(20).WithMessage("Postal code must not exceed 20 characters.");

        RuleFor(x => x.LogoUrl)
            .MaximumLength(500).WithMessage("Logo URL must not exceed 500 characters.");

        RuleForEach(x => x.Branches)
            .SetValidator(new AcademyBranchRequestValidator());

        RuleForEach(x => x.Sports)
            .SetValidator(new AcademySportRequestValidator());

        RuleForEach(x => x.Facilities)
            .SetValidator(new AcademyFacilityRequestValidator());

        RuleForEach(x => x.Memberships)
            .SetValidator(new AcademyMembershipRequestValidator());

        RuleForEach(x => x.WorkingHours)
            .SetValidator(new AcademyWorkingHourRequestValidator());
    }
}

public sealed class AcademyBranchRequestValidator : AbstractValidator<AcademyBranchRequest>
{
    public AcademyBranchRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Branch name is required.")
            .MaximumLength(200).WithMessage("Branch name must not exceed 200 characters.");

        RuleFor(x => x.ContactEmail)
            .EmailAddress().WithMessage("Invalid branch contact email address.")
            .MaximumLength(256).WithMessage("Branch contact email must not exceed 256 characters.")
            .When(x => !string.IsNullOrWhiteSpace(x.ContactEmail));
    }
}

public sealed class AcademySportRequestValidator : AbstractValidator<AcademySportRequest>
{
    public AcademySportRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Sport name is required.")
            .MaximumLength(100).WithMessage("Sport name must not exceed 100 characters.");
    }
}

public sealed class AcademyFacilityRequestValidator : AbstractValidator<AcademyFacilityRequest>
{
    public AcademyFacilityRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Facility name is required.")
            .MaximumLength(200).WithMessage("Facility name must not exceed 200 characters.");

        RuleFor(x => x.Capacity)
            .GreaterThan(0).WithMessage("Capacity must be greater than zero.")
            .When(x => x.Capacity.HasValue);
    }
}

public sealed class AcademyMembershipRequestValidator : AbstractValidator<AcademyMembershipRequest>
{
    public AcademyMembershipRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Membership name is required.")
            .MaximumLength(200).WithMessage("Membership name must not exceed 200 characters.");

        RuleFor(x => x.DurationDays)
            .GreaterThan(0).WithMessage("Membership duration must be greater than zero.");

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0).WithMessage("Membership price cannot be negative.");
    }
}

public sealed class AcademyWorkingHourRequestValidator : AbstractValidator<AcademyWorkingHourRequest>
{
    public AcademyWorkingHourRequestValidator()
    {
        RuleFor(x => x.DayOfWeek)
            .IsInEnum().WithMessage("Invalid day of week.");

        RuleFor(x => x.OpenTime)
            .NotNull().WithMessage("Open time is required.")
            .When(x => !x.IsClosed);

        RuleFor(x => x.CloseTime)
            .NotNull().WithMessage("Close time is required.")
            .When(x => !x.IsClosed);

        RuleFor(x => x)
            .Must(x => x.OpenTime < x.CloseTime)
            .WithMessage("Open time must be before close time.")
            .When(x => !x.IsClosed && x.OpenTime.HasValue && x.CloseTime.HasValue);
    }
}
