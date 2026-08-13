using SPORTSGURUKUL.Application.Academies.DTOs;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Academies.Common;

public static class AcademyFactory
{
    public static Academy Create(AcademyRequest request, Guid ownerUserId)
    {
        var now = DateTime.UtcNow;
        var academy = new Academy
        {
            Id = Guid.NewGuid(),
            OwnerUserId = ownerUserId,
            CreatedAt = now,
            UpdatedAt = now
        };

        Apply(academy, request, now);
        return academy;
    }

    public static void Update(Academy academy, AcademyRequest request)
        => Apply(academy, request, DateTime.UtcNow);

    private static void Apply(Academy academy, AcademyRequest request, DateTime now)
    {
        academy.Name = request.Name.Trim();
        academy.Profile = request.Profile?.Trim();
        academy.ContactEmail = request.ContactEmail?.Trim();
        academy.ContactPhone = request.ContactPhone?.Trim();
        academy.Address = request.Address?.Trim();
        academy.City = request.City?.Trim();
        academy.State = request.State?.Trim();
        academy.Country = request.Country?.Trim();
        academy.PostalCode = request.PostalCode?.Trim();
        academy.LogoUrl = request.LogoUrl?.Trim();
        academy.IsPublic = request.IsPublic;
        academy.Touch();

        academy.Branches.Clear();
        academy.Sports.Clear();
        academy.Facilities.Clear();
        academy.Memberships.Clear();
        academy.WorkingHours.Clear();

        foreach (var branch in request.Branches)
        {
            academy.Branches.Add(new AcademyBranch
            {
                Id = Guid.NewGuid(),
                AcademyId = academy.Id,
                Name = branch.Name.Trim(),
                Address = branch.Address?.Trim(),
                City = branch.City?.Trim(),
                State = branch.State?.Trim(),
                Country = branch.Country?.Trim(),
                PostalCode = branch.PostalCode?.Trim(),
                ContactEmail = branch.ContactEmail?.Trim(),
                ContactPhone = branch.ContactPhone?.Trim(),
                IsMain = branch.IsMain,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        foreach (var sport in request.Sports)
        {
            academy.Sports.Add(new AcademySport
            {
                Id = Guid.NewGuid(),
                AcademyId = academy.Id,
                Name = sport.Name.Trim(),
                CreatedAt = now
            });
        }

        foreach (var facility in request.Facilities)
        {
            academy.Facilities.Add(new AcademyFacility
            {
                Id = Guid.NewGuid(),
                AcademyId = academy.Id,
                Name = facility.Name.Trim(),
                Type = facility.Type?.Trim(),
                Capacity = facility.Capacity,
                Description = facility.Description?.Trim(),
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        foreach (var membership in request.Memberships)
        {
            academy.Memberships.Add(new AcademyMembership
            {
                Id = Guid.NewGuid(),
                AcademyId = academy.Id,
                Name = membership.Name.Trim(),
                Description = membership.Description?.Trim(),
                DurationDays = membership.DurationDays,
                Price = membership.Price,
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        foreach (var workingHour in request.WorkingHours)
        {
            academy.WorkingHours.Add(new AcademyWorkingHour
            {
                Id = Guid.NewGuid(),
                AcademyId = academy.Id,
                DayOfWeek = workingHour.DayOfWeek,
                OpenTime = workingHour.OpenTime,
                CloseTime = workingHour.CloseTime,
                IsClosed = workingHour.IsClosed,
                CreatedAt = now
            });
        }
    }
}
