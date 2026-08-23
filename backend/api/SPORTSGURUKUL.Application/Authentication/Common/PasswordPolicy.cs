namespace SPORTSGURUKUL.Application.Authentication.Common;

public static class PasswordPolicy
{
    public const int MinLength = 8;
    public const string Pattern = @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\w\s]).{8,}$";
    public const string Message =
        "Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number and a special character.";

    public const string MobilePattern = @"^\+?[0-9\s\-]{7,15}$";
    public const string MobileMessage = "Invalid mobile number.";
}
