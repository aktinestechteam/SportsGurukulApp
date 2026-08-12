namespace SPORTSGURUKUL.Domain.Constants;

public static class RoleNames
{
    public const string SystemAdmin = "SystemAdmin";
    public const string AcademyAdmin = "AcademyAdmin";
    public const string AcademyCoach = "AcademyCoach";
    public const string AcademyAthlete = "AcademyAthlete";
    public const string Coach = "Coach";
    public const string Athlete = "Athlete";
    public const string AppUser = "AppUser";

    public static readonly IReadOnlyList<string> All =
    [
        SystemAdmin,
        AcademyAdmin,
        AcademyCoach,
        AcademyAthlete,
        Coach,
        Athlete,
        AppUser
    ];
}
