using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Coaches.Common;

public static class CoachResponseMapper
{
    public static CoachResponse Map(AcademyCoach association)
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
            CreatedAt = association.AssignedAt
        };
    }

    public static CreateCoachResponse MapCreated(AcademyCoach association)
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
            Sports = MapSports(coach.Sports)
        };
    }

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
