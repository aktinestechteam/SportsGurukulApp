using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Common.Options;

namespace SPORTSGURUKUL.Tests.Athletes;

internal static class TestOptions
{
    public static IOptions<AppOptions> Create()
        => Options.Create(new AppOptions
        {
            UserIdPrefix = "SG-COACH",
            UserUserIdPrefix = "SG-USER",
            AthleteUserIdPrefix = "SG-ATH",
            UserIdDigits = 6,
            FrontendBaseUrl = "https://app.sportsgurukul.test",
            LoginBaseUrl = "https://app.sportsgurukul.test/login"
        });
}
