using Moq;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Queries;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Tests.Athletes;

public class GetAcademyAthletesQueryTests
{
    private readonly Guid _ownerUserId = Guid.NewGuid();
    private readonly Guid _academyId = Guid.NewGuid();

    private readonly Mock<IAcademyRepository> _academyRepository = new();
    private readonly Mock<IAthleteRepository> _athleteRepository = new();
    private readonly Mock<ICoachAthleteRepository> _coachAthleteRepository = new();
    private readonly Mock<ICurrentUserService> _currentUserService = new();

    public GetAcademyAthletesQueryTests()
    {
        _currentUserService.SetupGet(x => x.UserId).Returns(_ownerUserId);
        _academyRepository
            .Setup(x => x.GetByIdForOwnerAsync(_academyId, _ownerUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Academy { Id = _academyId, OwnerUserId = _ownerUserId });
        _coachAthleteRepository
            .Setup(x => x.GetByAcademyAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([]);
    }

    [Fact]
    public async Task GetAthletes_ReturnsMappedAthletes()
    {
        var athlete = new Athlete
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            DateOfBirth = new DateTime(2015, 3, 10),
            Gender = AthleteGender.Female,
            AgeGroup = "U12",
            Sports =
            [
                new AthleteSport
                {
                    SportId = Guid.NewGuid(),
                    IsPrimary = true,
                    Sport = new AcademySport { Id = Guid.NewGuid(), Name = "Tennis" }
                }
            ],
            User = new User { Id = Guid.NewGuid(), FirstName = "Anjali", LastName = "Sharma", Email = "a@b.com", MobileNumber = "+91 111", PublicUserId = "SG-ATH-000007" }
        };

        _athleteRepository
            .Setup(x => x.GetByAcademyAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<AcademyAthlete>
            {
                new()
                {
                    AcademyId = _academyId,
                    AthleteId = athlete.Id,
                    Status = AthleteStatus.Invited,
                    AssignedAt = DateTime.UtcNow,
                    Academy = new Academy { Id = _academyId, Name = "Dream Academy" },
                    Athlete = athlete
                }
            });

        var handler = new GetAcademyAthletesQueryHandler(
            _academyRepository.Object,
            _athleteRepository.Object,
            _coachAthleteRepository.Object,
            _currentUserService.Object);

        var response = await handler.Handle(new GetAcademyAthletesQuery(_academyId), CancellationToken.None);

        Assert.True(response.Success);
        var item = Assert.Single(response.Data!);
        Assert.Equal(athlete.Id, item.AthleteId);
        Assert.Equal("Anjali", item.FirstName);
        Assert.Equal("SG-ATH-000007", item.PublicUserId);
        Assert.Equal("U12", item.AgeGroup);
        Assert.Equal("Tennis", item.PrimarySport.Name);
        Assert.Null(item.SecondarySport);
        Assert.Equal("Dream Academy", item.AcademyName);
    }

    [Fact]
    public async Task GetAthletes_ReturnsMappedCoaches()
    {
        var athlete = new Athlete
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            DateOfBirth = new DateTime(2015, 3, 10),
            Gender = AthleteGender.Male,
            AgeGroup = "U12",
            Sports =
            [
                new AthleteSport
                {
                    SportId = Guid.NewGuid(),
                    IsPrimary = true,
                    Sport = new AcademySport { Id = Guid.NewGuid(), Name = "Cricket" }
                }
            ],
            User = new User { Id = Guid.NewGuid(), FirstName = "Anjali", LastName = "Sharma", Email = "a@b.com", MobileNumber = "+91 111", PublicUserId = "SG-ATH-000007" }
        };

        var coach = new Coach
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            User = new User { Id = Guid.NewGuid(), FirstName = "Suresh", LastName = "Raina" }
        };

        _athleteRepository
            .Setup(x => x.GetByAcademyAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<AcademyAthlete>
            {
                new()
                {
                    AcademyId = _academyId,
                    AthleteId = athlete.Id,
                    Status = AthleteStatus.Invited,
                    AssignedAt = DateTime.UtcNow,
                    Academy = new Academy { Id = _academyId, Name = "Dream Academy" },
                    Athlete = athlete
                }
            });

        _coachAthleteRepository
            .Setup(x => x.GetByAcademyAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CoachAthlete>
            {
                new()
                {
                    CoachId = coach.Id,
                    AthleteId = athlete.Id,
                    AcademyId = _academyId,
                    Coach = coach,
                    Athlete = athlete
                }
            });

        var handler = new GetAcademyAthletesQueryHandler(
            _academyRepository.Object,
            _athleteRepository.Object,
            _coachAthleteRepository.Object,
            _currentUserService.Object);

        var response = await handler.Handle(new GetAcademyAthletesQuery(_academyId), CancellationToken.None);

        Assert.True(response.Success);
        var item = Assert.Single(response.Data!);
        var mapped = Assert.Single(item.MappedCoaches);
        Assert.Equal(coach.Id, mapped.CoachId);
        Assert.Equal("Suresh Raina", mapped.Name);
    }

    [Fact]
    public async Task GetAthletes_NoMappings_ReturnsEmptyMappedCoaches()
    {
        var athlete = new Athlete
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            DateOfBirth = new DateTime(2015, 3, 10),
            Gender = AthleteGender.Male,
            AgeGroup = "U12",
            Sports =
            [
                new AthleteSport
                {
                    SportId = Guid.NewGuid(),
                    IsPrimary = true,
                    Sport = new AcademySport { Id = Guid.NewGuid(), Name = "Cricket" }
                }
            ],
            User = new User { Id = Guid.NewGuid(), FirstName = "Anjali", LastName = "Sharma", Email = "a@b.com", MobileNumber = "+91 111", PublicUserId = "SG-ATH-000007" }
        };

        _athleteRepository
            .Setup(x => x.GetByAcademyAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<AcademyAthlete>
            {
                new()
                {
                    AcademyId = _academyId,
                    AthleteId = athlete.Id,
                    Status = AthleteStatus.Invited,
                    AssignedAt = DateTime.UtcNow,
                    Academy = new Academy { Id = _academyId, Name = "Dream Academy" },
                    Athlete = athlete
                }
            });

        var handler = new GetAcademyAthletesQueryHandler(
            _academyRepository.Object,
            _athleteRepository.Object,
            _coachAthleteRepository.Object,
            _currentUserService.Object);

        var response = await handler.Handle(new GetAcademyAthletesQuery(_academyId), CancellationToken.None);

        Assert.True(response.Success);
        var item = Assert.Single(response.Data!);
        Assert.Empty(item.MappedCoaches);
    }

    [Fact]
    public async Task GetAthletes_NotAuthenticated_ThrowsUnauthorized()
    {
        _currentUserService.SetupGet(x => x.UserId).Returns(Guid.Empty);

        var handler = new GetAcademyAthletesQueryHandler(
            _academyRepository.Object,
            _athleteRepository.Object,
            _coachAthleteRepository.Object,
            _currentUserService.Object);

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(new GetAcademyAthletesQuery(_academyId), CancellationToken.None));

        Assert.Equal(401, exception.StatusCode);
    }

    [Fact]
    public async Task GetAthletes_AcademyNotOwned_ThrowsNotFound()
    {
        _academyRepository
            .Setup(x => x.GetByIdForOwnerAsync(_academyId, _ownerUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Academy?)null);

        var handler = new GetAcademyAthletesQueryHandler(
            _academyRepository.Object,
            _athleteRepository.Object,
            _coachAthleteRepository.Object,
            _currentUserService.Object);

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(new GetAcademyAthletesQuery(_academyId), CancellationToken.None));

        Assert.Equal(404, exception.StatusCode);
    }
}
