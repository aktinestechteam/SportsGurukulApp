using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Commands;
using SPORTSGURUKUL.Application.Athletes.DTOs;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Constants;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Tests.Athletes;

public class CreateAcademyAthleteCommandTests
{
    private readonly Guid _ownerUserId = Guid.NewGuid();
    private readonly Guid _academyId = Guid.NewGuid();
    private readonly Guid _sportId = Guid.NewGuid();
    private readonly Guid _secondarySportId = Guid.NewGuid();
    private readonly Guid _branchId = Guid.NewGuid();

    private readonly Mock<IAcademyRepository> _academyRepository = new();
    private readonly Mock<IUserRepository> _userRepository = new();
    private readonly Mock<IRoleRepository> _roleRepository = new();
    private readonly Mock<IAthleteRepository> _athleteRepository = new();
    private readonly Mock<ICoachAthleteRepository> _coachAthleteRepository = new();
    private readonly Mock<IPublicUserIdGenerator> _publicUserIdGenerator = new();
    private readonly Mock<ITemporaryPasswordGenerator> _temporaryPasswordGenerator = new();
    private readonly Mock<IPasswordHasher> _passwordHasher = new();
    private readonly Mock<IEmailService> _emailService = new();
    private readonly Mock<ICurrentUserService> _currentUserService = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();

    public CreateAcademyAthleteCommandTests()
    {
        _currentUserService.SetupGet(x => x.IsAuthenticated).Returns(true);
        _currentUserService.SetupGet(x => x.UserId).Returns(_ownerUserId);
        _publicUserIdGenerator
            .Setup(x => x.GenerateAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync("SG-ATH-000001");
        _temporaryPasswordGenerator.Setup(x => x.Generate()).Returns("Temp@1234");
        _passwordHasher.Setup(x => x.HashPassword(It.IsAny<string>())).Returns("hashed-password");
        _emailService
            .Setup(x => x.SendAthleteCredentialsAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _userRepository
            .Setup(x => x.PublicUserIdExistsAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var academy = BuildAcademy();
        _academyRepository
            .Setup(x => x.GetByIdAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(academy);

        _roleRepository
            .Setup(x => x.GetByNameAsync(RoleNames.AcademyAthlete, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Role { Id = Guid.NewGuid(), Name = RoleNames.AcademyAthlete });

        _academyRepository
            .Setup(x => x.GetAcademyCoachIdsAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([]);
    }

    [Fact]
    public async Task Create_AsOwner_SucceedsAndReturnsCreatedAthlete()
    {
        var handler = CreateHandler();
        var command = BuildCommand();

        var response = await handler.Handle(command, CancellationToken.None);

        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal("SG-ATH-000001", response.Data!.PublicUserId);
        Assert.Equal("Cricket", response.Data.PrimarySport.Name);
        Assert.Equal("Basketball", response.Data.SecondarySport!.Name);
        Assert.Equal("SG-ATH", response.Data.PublicUserId[..6]);
        Assert.NotEqual("Temp@1234", response.Data.PublicUserId);

        _unitOfWork.Verify(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(x => x.CommitAsync(It.IsAny<CancellationToken>()), Times.Once);
        _userRepository.Verify(x => x.AddAsync(It.Is<User>(u =>
            u.NormalizedEmail == "ATHLETE@EXAMPLE.COM" &&
            u.PublicUserId == "SG-ATH-000001" &&
            u.PasswordHash == "hashed-password" &&
            u.UserRoles.Count == 1 &&
            u.UserRoles.First().RoleId == _roleRepository.Object.GetByNameAsync(RoleNames.AcademyAthlete, default).Result!.Id), It.IsAny<CancellationToken>()), Times.Once);

        _emailService.Verify(x => x.SendAthleteCredentialsAsync(
            "athlete@example.com",
            "Ravi",
            "Dream Academy",
            "SG-ATH-000001",
            "Temp@1234",
            "https://app.sportsgurukul.test/login",
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Create_AssignsAgeGroupAndSports()
    {
        Athlete? createdAthlete = null;
        _athleteRepository
            .Setup(x => x.AddAsync(It.IsAny<Athlete>(), It.IsAny<CancellationToken>()))
            .Callback<Athlete, CancellationToken>((a, _) => createdAthlete = a);

        var handler = CreateHandler();
        var response = await handler.Handle(BuildCommand(), CancellationToken.None);

        Assert.NotNull(createdAthlete);
        Assert.Equal("U12", createdAthlete!.AgeGroup);
        Assert.Equal(2, createdAthlete.Sports.Count);
        Assert.Single(createdAthlete.Sports, s => s.IsPrimary && s.SportId == _sportId);
        Assert.Single(createdAthlete.Sports, s => !s.IsPrimary && s.SportId == _secondarySportId);
        Assert.NotNull(response.Data);
        Assert.Equal("U12", response.Data!.AgeGroup);
    }

    [Fact]
    public async Task Create_NotAuthenticated_ThrowsUnauthorized()
    {
        _currentUserService.SetupGet(x => x.IsAuthenticated).Returns(false);
        _currentUserService.SetupGet(x => x.UserId).Returns(Guid.Empty);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(401, exception.StatusCode);
    }

    [Fact]
    public async Task Create_AcademyNotFound_ThrowsNotFound()
    {
        _academyRepository
            .Setup(x => x.GetByIdAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Academy?)null);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(404, exception.StatusCode);
        _unitOfWork.Verify(x => x.RollbackAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Create_NotOwner_ThrowsForbidden()
    {
        var otherOwner = BuildAcademy();
        otherOwner.OwnerUserId = Guid.NewGuid();
        _academyRepository
            .Setup(x => x.GetByIdAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(otherOwner);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(403, exception.StatusCode);
    }

    [Fact]
    public async Task Create_DuplicateEmail_ThrowsConflict()
    {
        _userRepository
            .Setup(x => x.EmailExistsAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(409, exception.StatusCode);
        _userRepository.Verify(x => x.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task Create_DuplicateMobile_ThrowsConflict()
    {
        _userRepository
            .Setup(x => x.MobileNumberExistsAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(409, exception.StatusCode);
    }

    [Fact]
    public async Task Create_EmailFails_RollsBackAndThrowsServiceUnavailable()
    {
        _emailService
            .Setup(x => x.SendAthleteCredentialsAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(503, exception.StatusCode);
        _unitOfWork.Verify(x => x.RollbackAsync(It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(x => x.CommitAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task Create_PublicUserIdCollision_RetriesUntilUnique()
    {
        _publicUserIdGenerator
            .SetupSequence(x => x.GenerateAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync("SG-ATH-000001")
            .ReturnsAsync("SG-ATH-000002")
            .ReturnsAsync("SG-ATH-000003");
        _userRepository
            .Setup(x => x.PublicUserIdExistsAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((string candidate, CancellationToken _) =>
                candidate is "SG-ATH-000001" or "SG-ATH-000002");

        var handler = CreateHandler();
        var response = await handler.Handle(BuildCommand(), CancellationToken.None);

        Assert.True(response.Success);
        Assert.Equal("SG-ATH-000003", response.Data!.PublicUserId);
        _publicUserIdGenerator.Verify(
            x => x.GenerateAsync("SG-ATH", It.IsAny<CancellationToken>()),
            Times.Exactly(3));
    }

    [Fact]
    public async Task Create_PrimarySportNotInAcademy_ThrowsValidationException()
    {
        var request = BuildRequest();
        request.PrimarySportId = Guid.NewGuid();

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            handler.Handle(new CreateAcademyAthleteCommand(_academyId, request), CancellationToken.None));

        Assert.True(exception.Errors.ContainsKey("primarySportId"));
    }

    [Fact]
    public async Task Create_SecondarySportEqualsPrimary_ThrowsValidationException()
    {
        var request = BuildRequest();
        request.SecondarySportId = request.PrimarySportId;

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            handler.Handle(new CreateAcademyAthleteCommand(_academyId, request), CancellationToken.None));

        Assert.True(exception.Errors.ContainsKey("secondarySportId"));
    }

    [Fact]
    public async Task Create_BranchRequiredWhenAcademyHasBranches_ThrowsValidationException()
    {
        var request = BuildRequest();
        request.BranchId = null;

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            handler.Handle(new CreateAcademyAthleteCommand(_academyId, request), CancellationToken.None));

        Assert.True(exception.Errors.ContainsKey("branchId"));
    }

    [Fact]
    public async Task Create_SecondarySportNotInAcademy_ThrowsValidationException()
    {
        var request = BuildRequest();
        request.SecondarySportId = Guid.NewGuid();

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            handler.Handle(new CreateAcademyAthleteCommand(_academyId, request), CancellationToken.None));

        Assert.True(exception.Errors.ContainsKey("secondarySportId"));
    }

    [Fact]
    public async Task Create_WithCoachIds_AddsCoachMappings()
    {
        var coachId = Guid.NewGuid();
        _academyRepository
            .Setup(x => x.GetAcademyCoachIdsAsync(_academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([coachId]);

        Athlete? createdAthlete = null;
        _athleteRepository
            .Setup(x => x.AddAsync(It.IsAny<Athlete>(), It.IsAny<CancellationToken>()))
            .Callback<Athlete, CancellationToken>((a, _) => createdAthlete = a);

        var request = BuildRequest();
        request.CoachIds = [coachId];
        var handler = CreateHandler();

        await handler.Handle(new CreateAcademyAthleteCommand(_academyId, request), CancellationToken.None);

        Assert.NotNull(createdAthlete);
        var mapping = Assert.Single(createdAthlete!.CoachMappings);
        Assert.Equal(coachId, mapping.CoachId);
        Assert.Equal(_academyId, mapping.AcademyId);
        Assert.Equal(createdAthlete.Id, mapping.AthleteId);
    }

    [Fact]
    public async Task Create_CoachNotInAcademy_ThrowsValidationException()
    {
        var request = BuildRequest();
        request.CoachIds = [Guid.NewGuid()];

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            handler.Handle(new CreateAcademyAthleteCommand(_academyId, request), CancellationToken.None));

        Assert.True(exception.Errors.ContainsKey("coachIds"));
    }

    private CreateAcademyAthleteCommandHandler CreateHandler()
        => new(
            _academyRepository.Object,
            _userRepository.Object,
            _roleRepository.Object,
            _athleteRepository.Object,
            _coachAthleteRepository.Object,
            _publicUserIdGenerator.Object,
            _temporaryPasswordGenerator.Object,
            _passwordHasher.Object,
            _emailService.Object,
            _currentUserService.Object,
            _unitOfWork.Object,
            TestOptions.Create(),
            NullLogger<CreateAcademyAthleteCommandHandler>.Instance);

    private CreateAcademyAthleteCommand BuildCommand()
        => new(_academyId, BuildRequest());

    private CreateAthleteRequest BuildRequest()
        => new()
        {
            FirstName = "Ravi",
            LastName = "Kumar",
            Email = "athlete@example.com",
            MobileNumber = "+91 9876543210",
            DateOfBirth = DateTime.UtcNow.Date.AddYears(-11).AddDays(-10),
            Gender = AthleteGender.Male,
            BranchId = _branchId,
            PrimarySportId = _sportId,
            SecondarySportId = _secondarySportId,
            Address = "12 Park Street",
            EmergencyContact = "+91 9988776655"
        };

    private Academy BuildAcademy()
        => new()
        {
            Id = _academyId,
            Name = "Dream Academy",
            OwnerUserId = _ownerUserId,
            Branches =
            [
                new AcademyBranch { Id = _branchId, Name = "Main Branch" }
            ],
            Sports =
            [
                new AcademySport { Id = _sportId, Name = "Cricket" },
                new AcademySport { Id = _secondarySportId, Name = "Basketball" }
            ]
        };
}
