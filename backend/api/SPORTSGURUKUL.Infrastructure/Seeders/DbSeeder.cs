using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Domain.Constants;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;
using SPORTSGURUKUL.Infrastructure.Persistence;

namespace SPORTSGURUKUL.Infrastructure.Seeders;

public class DbSeeder
{
    private readonly AppDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ILogger<DbSeeder> _logger;

    public DbSeeder(
        AppDbContext context,
        IPasswordHasher passwordHasher,
        ILogger<DbSeeder> logger)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _logger = logger;
    }

    private const string DemoEmail = "admin@sportsgurukul.com";
    private const string DemoPassword = "Admin@123";

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        await SeedRolesAsync(cancellationToken);
        await SeedDemoDataAsync(cancellationToken);
    }

    private async Task SeedRolesAsync(CancellationToken cancellationToken)
    {
        if (await _context.Roles.AnyAsync(cancellationToken))
        {
            return;
        }

        var now = DateTime.UtcNow;
        var roles = RoleNames.All.Select((name, index) => new Role
        {
            Id = Guid.NewGuid(),
            Name = name,
            Description = $"System role: {name}",
            IsSystemRole = true,
            CreatedAt = now
        }).ToList();

        _context.Roles.AddRange(roles);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Seeded {RoleCount} system roles", roles.Count);
    }

    /// <summary>
    /// Seeds a demo academy admin (only when the database has no users) and a
    /// sample academy so the academy feature can be explored immediately after
    /// setup. The sample academy is attached to the demo admin, or to the first
    /// existing user when the database already has users.
    /// Sign in with admin@sportsgurukul.com / Admin@123
    /// </summary>
    private async Task SeedDemoDataAsync(CancellationToken cancellationToken)
    {
        var demoUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Email == DemoEmail, cancellationToken);

        if (demoUser is null && !await _context.Users.AnyAsync(cancellationToken))
        {
            demoUser = BuildDemoUser();
            _context.Users.Add(demoUser);
        }

        if (await _context.Academies.AnyAsync(cancellationToken))
        {
            await _context.SaveChangesAsync(cancellationToken);
            return;
        }

        var owner = demoUser ?? await _context.Users
            .OrderBy(u => u.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
        if (owner is null)
        {
            return;
        }

        var academy = BuildSampleAcademy(owner.Id);
        _context.Academies.Add(academy);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "Seeded demo academy {AcademyName} for {Email}",
            academy.Name,
            owner.Email);
    }

    private User BuildDemoUser()
    {
        var adminRole = _context.Roles
            .FirstOrDefault(r => r.Name == RoleNames.AcademyAdmin);

        var now = DateTime.UtcNow;
        var ownerId = Guid.NewGuid();

        var owner = new User
        {
            Id = ownerId,
            FirstName = "Demo",
            LastName = "Admin",
            Email = DemoEmail,
            NormalizedEmail = DemoEmail.ToUpperInvariant(),
            MobileNumber = "+91 9876543210",
            NormalizedMobileNumber = "+91 9876543210",
            PasswordHash = _passwordHasher.HashPassword(DemoPassword),
            AccountStatus = AccountStatus.Active,
            IsEmailVerified = true,
            CreatedAt = now,
            UpdatedAt = now
        };

        if (adminRole is not null)
        {
            owner.UserRoles.Add(new UserRole
            {
                UserId = ownerId,
                RoleId = adminRole.Id,
                AssignedAt = now,
                AssignedBy = null,
                IsActive = true
            });
        }

        return owner;
    }

    private Academy BuildSampleAcademy(Guid ownerId)
    {
        var now = DateTime.UtcNow;
        var academyId = Guid.NewGuid();

        var academy = new Academy
        {
            Id = academyId,
            OwnerUserId = ownerId,
            Name = "Sports Gurukul Academy",
            Profile = "Premier multi-sport academy focused on holistic athlete development.",
            ContactEmail = "hello@sportsgurukul.com",
            ContactPhone = "+91 9876543210",
            Address = "No. 12, Stadium Road",
            City = "Bengaluru",
            State = "Karnataka",
            Country = "India",
            PostalCode = "560001",
            IsPublic = true,
            CreatedAt = now,
            UpdatedAt = now,
            Branches =
            [
                new AcademyBranch
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Main Campus",
                    Address = "No. 12, Stadium Road",
                    City = "Bengaluru",
                    State = "Karnataka",
                    Country = "India",
                    PostalCode = "560001",
                    ContactEmail = "hello@sportsgurukul.com",
                    ContactPhone = "+91 9876543210",
                    IsMain = true,
                    CreatedAt = now,
                    UpdatedAt = now
                }
            ],
            Sports =
            [
                new AcademySport { Id = Guid.NewGuid(), AcademyId = academyId, Name = "Cricket", CreatedAt = now },
                new AcademySport { Id = Guid.NewGuid(), AcademyId = academyId, Name = "Football", CreatedAt = now },
                new AcademySport { Id = Guid.NewGuid(), AcademyId = academyId, Name = "Tennis", CreatedAt = now },
                new AcademySport { Id = Guid.NewGuid(), AcademyId = academyId, Name = "Badminton", CreatedAt = now },
                new AcademySport { Id = Guid.NewGuid(), AcademyId = academyId, Name = "Swimming", CreatedAt = now }
            ],
            Facilities =
            [
                new AcademyFacility
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Cricket Ground",
                    Type = "Outdoor Ground",
                    Capacity = 500,
                    Description = "Well-maintained turf cricket ground with practice nets.",
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now
                },
                new AcademyFacility
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Indoor Court",
                    Type = "Indoor",
                    Capacity = 40,
                    Description = "Multi-purpose indoor court for badminton and tennis.",
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now
                },
                new AcademyFacility
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Fitness Gym",
                    Type = "Gym",
                    Capacity = 60,
                    Description = "Strength and conditioning gym for athletes.",
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now
                },
                new AcademyFacility
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Swimming Pool",
                    Type = "Pool",
                    Capacity = 80,
                    Description = "Olympic-size swimming pool with lap lanes.",
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now
                }
            ],
            Memberships =
            [
                new AcademyMembership
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Monthly",
                    Description = "Access to all facilities for one month.",
                    DurationDays = 30,
                    Price = 2500m,
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now
                },
                new AcademyMembership
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Quarterly",
                    Description = "Access to all facilities for three months.",
                    DurationDays = 90,
                    Price = 6750m,
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now
                },
                new AcademyMembership
                {
                    Id = Guid.NewGuid(),
                    AcademyId = academyId,
                    Name = "Annual",
                    Description = "Full year access with priority slot booking.",
                    DurationDays = 365,
                    Price = 24000m,
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now
                }
            ]
        };

        for (var day = DayOfWeek.Monday; day <= DayOfWeek.Saturday; day++)
        {
            academy.WorkingHours.Add(new AcademyWorkingHour
            {
                Id = Guid.NewGuid(),
                AcademyId = academyId,
                DayOfWeek = day,
                OpenTime = day == DayOfWeek.Saturday ? new TimeOnly(7, 0) : new TimeOnly(6, 0),
                CloseTime = day == DayOfWeek.Saturday ? new TimeOnly(18, 0) : new TimeOnly(21, 0),
                IsClosed = false,
                CreatedAt = now
            });
        }

        academy.WorkingHours.Add(new AcademyWorkingHour
        {
            Id = Guid.NewGuid(),
            AcademyId = academyId,
            DayOfWeek = DayOfWeek.Sunday,
            OpenTime = null,
            CloseTime = null,
            IsClosed = true,
            CreatedAt = now
        });

        return academy;
    }
}
