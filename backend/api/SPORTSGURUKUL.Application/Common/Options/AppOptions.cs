namespace SPORTSGURUKUL.Application.Common.Options;

public class AppOptions
{
    public string FrontendBaseUrl { get; set; } = string.Empty;
    public string ResetPasswordBaseUrl { get; set; } = string.Empty;
    public string EmailVerificationBaseUrl { get; set; } = string.Empty;

    /// <summary>Base login URL included in account invitation emails.</summary>
    public string LoginBaseUrl { get; set; } = string.Empty;

    /// <summary>Prefix used when generating the public user identifier.</summary>
    public string UserIdPrefix { get; set; } = "SG-COACH";

    /// <summary>Number of digits in the numeric suffix of the public user identifier.</summary>
    public int UserIdDigits { get; set; } = 6;
}
