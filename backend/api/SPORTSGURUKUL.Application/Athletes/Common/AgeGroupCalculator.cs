namespace SPORTSGURUKUL.Application.Athletes.Common;

public static class AgeGroupCalculator
{
    /// <summary>
    /// Computes the athlete's age in completed years at the given reference
    /// date based on the date of birth.
    /// </summary>
    public static int CalculateAge(DateTime dateOfBirth, DateTime? referenceDate = null)
    {
        var today = (referenceDate ?? DateTime.UtcNow).Date;
        var birth = dateOfBirth.Date;
        var age = today.Year - birth.Year;
        if (today < birth.AddYears(age))
        {
            age--;
        }

        return age;
    }

    /// <summary>
    /// Maps an age to a competition age group: U10, U12, U14, U16, U18 or Adult.
    /// </summary>
    public static string CalculateAgeGroup(DateTime dateOfBirth, DateTime? referenceDate = null)
    {
        var age = CalculateAge(dateOfBirth, referenceDate);

        return age switch
        {
            < 10 => "U10",
            < 12 => "U12",
            < 14 => "U14",
            < 16 => "U16",
            < 18 => "U18",
            _ => "Adult"
        };
    }
}
