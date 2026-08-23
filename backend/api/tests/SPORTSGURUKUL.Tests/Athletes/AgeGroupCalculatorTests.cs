using SPORTSGURUKUL.Application.Athletes.Common;

namespace SPORTSGURUKUL.Tests.Athletes;

public class AgeGroupCalculatorTests
{
    [Theory]
    [InlineData(9, "U10")]
    [InlineData(10, "U12")]
    [InlineData(11, "U12")]
    [InlineData(12, "U14")]
    [InlineData(13, "U14")]
    [InlineData(14, "U16")]
    [InlineData(15, "U16")]
    [InlineData(16, "U18")]
    [InlineData(17, "U18")]
    [InlineData(18, "Adult")]
    [InlineData(35, "Adult")]
    public void CalculateAgeGroup_MapsAgeBoundaries(int age, string expected)
    {
        var dateOfBirth = DateTime.UtcNow.Date.AddYears(-age).AddDays(-1);

        var result = AgeGroupCalculator.CalculateAgeGroup(dateOfBirth);

        Assert.Equal(expected, result);
    }

    [Fact]
    public void CalculateAge_UsesBirthdayToBoundary()
    {
        var reference = new DateTime(2026, 8, 14);
        var bornJustBeforeBirthday = new DateTime(2015, 8, 15);

        Assert.Equal(10, AgeGroupCalculator.CalculateAge(bornJustBeforeBirthday, reference));
        Assert.Equal("U12", AgeGroupCalculator.CalculateAgeGroup(bornJustBeforeBirthday, reference));
    }
}
