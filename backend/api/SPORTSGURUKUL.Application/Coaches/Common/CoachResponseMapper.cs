using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Coaches.Common;

public static class CoachResponseMapper
{
    public static CoachResponse Map(AcademyCoach association, IEnumerable<CoachAthlete>? mappings = null)
    {
        var coach = association.Coach;
        var user = coach.User;

        return new CoachResponse
        {
            CoachId = coach.Id,
            UserId = user.Id,
            PublicUserId = user.PublicUserId,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            MobileNumber = user.MobileNumber,
            AcademyId = association.AcademyId,
            AcademyName = association.Academy.Name,
            BranchId = association.BranchId,
            BranchName = association.Branch?.Name,
            Status = association.Status,
            Sports = MapSports(coach.Sports),
            MappedAthletes = MapMappedAthletes(mappings),
            CreatedAt = association.AssignedAt
        };
    }

    public static CreateCoachResponse MapCreated(AcademyCoach association, IEnumerable<CoachAthlete>? mappings = null)
    {
        var coach = association.Coach;
        var user = coach.User;

        return new CreateCoachResponse
        {
            CoachId = coach.Id,
            PublicUserId = user.PublicUserId,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            MobileNumber = user.MobileNumber,
            AcademyId = association.AcademyId,
            AcademyName = association.Academy.Name,
            BranchId = association.BranchId,
            BranchName = association.Branch?.Name,
            Status = association.Status,
            Sports = MapSports(coach.Sports),
            MappedAthletes = MapMappedAthletes(mappings)
        };
    }

    private static List<MappedAthleteResponse> MapMappedAthletes(IEnumerable<CoachAthlete>? mappings)
        => mappings?
            .OrderBy(ca => ca.Athlete.User.FirstName)
            .ThenBy(ca => ca.Athlete.User.LastName)
            .Select(ca => new MappedAthleteResponse
            {
                AthleteId = ca.AthleteId,
                Name = BuildFullName(ca.Athlete.User.FirstName, ca.Athlete.User.LastName)
            })
            .ToList() ?? [];

    private static string BuildFullName(string firstName, string lastName)
        => string.IsNullOrWhiteSpace(lastName) ? firstName : $"{firstName} {lastName}".Trim();

    private static List<CoachSportResponse> MapSports(IEnumerable<CoachSport> sports)
        => sports
            .OrderBy(s => s.Sport.Name)
            .Select(s => new CoachSportResponse
            {
                SportId = s.SportId,
                Name = s.Sport.Name,
                Specialization = s.Specialization
            })
            .ToList();
}
