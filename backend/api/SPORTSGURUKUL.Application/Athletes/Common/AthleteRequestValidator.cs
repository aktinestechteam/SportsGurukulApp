using FluentValidation;
using SPORTSGURUKUL.Application.Authentication.Common;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Application.Athletes.Common;

public sealed class CreateAthleteRequestValidator : AbstractValidator<CreateAthleteRequest>
{
    public CreateAthleteRequestValidator()
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

        RuleFor(x => x.DateOfBirth)
            .NotEmpty().WithMessage("Date of birth is required.")
            .Must(BeInThePast).WithMessage("Date of birth cannot be in the future.")
            .Must(HaveValidAge).WithMessage("Date of birth is not valid for an athlete.");

        RuleFor(x => x.Gender)
            .IsInEnum().WithMessage("Invalid gender.");

        RuleFor(x => x.SportIds)
            .NotEmpty().WithMessage("At least one sport must be selected.")
            .Must(sports => sports.Count == sports.Distinct().Count())
            .WithMessage("Duplicate sports are not allowed.");

        RuleFor(x => x.CoachIds)
            .Must(coaches => coaches.Count == coaches.Distinct().Count())
            .When(x => x.CoachIds.Count > 0)
            .WithMessage("Duplicate coaches are not allowed.");

        RuleFor(x => x.Address)
            .MaximumLength(500).WithMessage("Address must not exceed 500 characters.");

        RuleFor(x => x.EmergencyContact)
            .Matches(PasswordPolicy.MobilePattern)
            .When(x => !string.IsNullOrWhiteSpace(x.EmergencyContact))
            .WithMessage("Emergency contact is not a valid mobile number.");
    }

    private static bool BeInThePast(DateTime dateOfBirth)
        => dateOfBirth.Date < DateTime.UtcNow.Date;

    private static bool HaveValidAge(DateTime dateOfBirth)
    {
        var age = AgeGroupCalculator.CalculateAge(dateOfBirth);
        return age is >= 4 and <= 100;
    }
}
