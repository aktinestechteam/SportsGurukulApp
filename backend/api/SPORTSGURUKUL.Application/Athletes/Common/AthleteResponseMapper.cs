using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Athletes.Common;

public static class AthleteResponseMapper
{
    public static AthleteResponse Map(AcademyAthlete association)
    {
        var athlete = association.Athlete;
        var user = athlete.User;

        return new AthleteResponse
        {
            AthleteId = athlete.Id,
            UserId = user.Id,
            PublicUserId = user.PublicUserId,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            MobileNumber = user.MobileNumber,
            DateOfBirth = athlete.DateOfBirth,
            Gender = athlete.Gender,
            AgeGroup = athlete.AgeGroup,
            Address = athlete.Address,
            EmergencyContact = athlete.EmergencyContact,
            AcademyId = association.AcademyId,
            AcademyName = association.Academy.Name,
            BranchId = association.BranchId,
            BranchName = association.Branch?.Name,
            Status = association.Status,
            PrimarySport = MapPrimarySport(athlete.Sports),
            SecondarySport = MapSecondarySport(athlete.Sports),
            CreatedAt = association.AssignedAt
        };
    }

    public static CreateAthleteResponse MapCreated(AcademyAthlete association)
    {
        var athlete = association.Athlete;
        var user = athlete.User;

        return new CreateAthleteResponse
        {
            AthleteId = athlete.Id,
            PublicUserId = user.PublicUserId,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            MobileNumber = user.MobileNumber,
            DateOfBirth = athlete.DateOfBirth,
            Gender = athlete.Gender,
            AgeGroup = athlete.AgeGroup,
            AcademyId = association.AcademyId,
            AcademyName = association.Academy.Name,
            BranchId = association.BranchId,
            BranchName = association.Branch?.Name,
            Status = association.Status,
            PrimarySport = MapPrimarySport(athlete.Sports),
            SecondarySport = MapSecondarySport(athlete.Sports)
        };
    }

    private static AthleteSportResponse MapPrimarySport(IEnumerable<AthleteSport> sports)
        => sports
            .Where(s => s.IsPrimary)
            .Select(s => new AthleteSportResponse
            {
                SportId = s.SportId,
                Name = s.Sport.Name
            })
            .First();

    private static AthleteSportResponse? MapSecondarySport(IEnumerable<AthleteSport> sports)
        => sports
            .Where(s => !s.IsPrimary)
            .Select(s => new AthleteSportResponse
            {
                SportId = s.SportId,
                Name = s.Sport.Name
            })
            .FirstOrDefault();
}
