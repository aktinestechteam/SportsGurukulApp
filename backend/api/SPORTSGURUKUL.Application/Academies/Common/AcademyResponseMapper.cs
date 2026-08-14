using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Academies.Common;

public static class AcademyResponseMapper
{
    public static AcademyResponse Map(Academy academy)
        => new()
        {
            AcademyId = academy.Id,
            Name = academy.Name,
            Profile = academy.Profile,
            ContactEmail = academy.ContactEmail,
            ContactPhone = academy.ContactPhone,
            Address = academy.Address,
            City = academy.City,
            State = academy.State,
            Country = academy.Country,
            PostalCode = academy.PostalCode,
            LogoUrl = academy.LogoUrl,
            IsPublic = academy.IsPublic,
            OwnerUserId = academy.OwnerUserId,
            CreatedAt = academy.CreatedAt,
            UpdatedAt = academy.UpdatedAt,
            CoachCount = academy.CoachAssociations.Count,
            Branches = academy.Branches.Select(MapBranch).ToList(),
            Sports = academy.Sports.Select(MapSport).ToList(),
            Facilities = academy.Facilities.Select(MapFacility).ToList(),
            Memberships = academy.Memberships.Select(MapMembership).ToList(),
            WorkingHours = academy.WorkingHours.Select(MapWorkingHour).ToList()
        };

    private static AcademyBranchResponse MapBranch(AcademyBranch branch)
        => new()
        {
            BranchId = branch.Id,
            Name = branch.Name,
            Address = branch.Address,
            City = branch.City,
            State = branch.State,
            Country = branch.Country,
            PostalCode = branch.PostalCode,
            ContactEmail = branch.ContactEmail,
            ContactPhone = branch.ContactPhone,
            IsMain = branch.IsMain
        };

    private static AcademySportResponse MapSport(AcademySport sport)
        => new()
        {
            SportId = sport.Id,
            Name = sport.Name
        };

    private static AcademyFacilityResponse MapFacility(AcademyFacility facility)
        => new()
        {
            FacilityId = facility.Id,
            Name = facility.Name,
            Type = facility.Type,
            Capacity = facility.Capacity,
            Description = facility.Description,
            IsActive = facility.IsActive
        };

    private static AcademyMembershipResponse MapMembership(AcademyMembership membership)
        => new()
        {
            MembershipId = membership.Id,
            Name = membership.Name,
            Description = membership.Description,
            DurationDays = membership.DurationDays,
            Price = membership.Price,
            IsActive = membership.IsActive
        };

    private static AcademyWorkingHourResponse MapWorkingHour(AcademyWorkingHour workingHour)
        => new()
        {
            WorkingHourId = workingHour.Id,
            DayOfWeek = workingHour.DayOfWeek,
            OpenTime = workingHour.OpenTime,
            CloseTime = workingHour.CloseTime,
            IsClosed = workingHour.IsClosed
        };
}
