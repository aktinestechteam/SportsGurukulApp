using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Application.Athletes.Commands;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Application.Common.Exceptions;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Domain.Enums;

namespace SPORTSGURUKUL.Tests.Athletes;

public class DeleteAcademyAthleteCommandTests
{
    private readonly Guid _ownerUserId = Guid.NewGuid();
    private readonly Guid _academyId = Guid.NewGuid();
    private readonly Guid _athleteId = Guid.NewGuid();
    private readonly Guid _userId = Guid.NewGuid();

    private readonly Mock<IAcademyRepository> _academyRepository = new();
    private readonly Mock<IUserRepository> _userRepository = new();
    private readonly Mock<IRefreshTokenRepository> _refreshTokenRepository = new();
    private readonly Mock<IAthleteRepository> _athleteRepository = new();
    private readonly Mock<ICoachAthleteRepository> _coachAthleteRepository = new();
    private readonly Mock<ICurrentUserService> _currentUserService = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();

    public DeleteAcademyAthleteCommandTests()
    {
        _currentUserService.SetupGet(x => x.UserId).Returns(_ownerUserId);

        _academyRepository
            .Setup(x => x.GetByIdForOwnerAsync(_academyId, _ownerUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Academy { Id = _academyId, OwnerUserId = _ownerUserId });

        _athleteRepository
            .Setup(x => x.GetByAcademyAndAthleteAsync(_academyId, _athleteId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(BuildAssociation());

        _athleteRepository
            .Setup(x => x.HasOtherAssociationsAsync(_athleteId, _academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);
    }

    [Fact]
    public async Task Delete_WithNoOtherAssociations_RemovesFullChain()
    {
        var handler = CreateHandler();

        var response = await handler.Handle(BuildCommand(), CancellationToken.None);

        Assert.True(response.Success);
        _coachAthleteRepository.Verify(
            x => x.RemoveByAthleteAsync(_athleteId, _academyId, It.IsAny<CancellationToken>()),
            Times.Once);
        _athleteRepository.Verify(
            x => x.RemoveAssociationAsync(_academyId, _athleteId, It.IsAny<CancellationToken>()),
            Times.Once);
        _refreshTokenRepository.Verify(x => x.RemoveByUserAsync(_userId, It.IsAny<CancellationToken>()), Times.Once);
        _userRepository.Verify(x => x.RemoveRolesAsync(_userId, It.IsAny<CancellationToken>()), Times.Once);
        _athleteRepository.Verify(x => x.RemoveAthleteAsync(_athleteId, It.IsAny<CancellationToken>()), Times.Once);
        _userRepository.Verify(x => x.DeleteAsync(_userId, It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(x => x.CommitAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Delete_WithOtherAssociations_OnlyRemovesThisAssociation()
    {
        _athleteRepository
            .Setup(x => x.HasOtherAssociationsAsync(_athleteId, _academyId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var handler = CreateHandler();
        var response = await handler.Handle(BuildCommand(), CancellationToken.None);

        Assert.True(response.Success);
        _athleteRepository.Verify(
            x => x.RemoveAssociationAsync(_academyId, _athleteId, It.IsAny<CancellationToken>()),
            Times.Once);
        _refreshTokenRepository.Verify(x => x.RemoveByUserAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()), Times.Never);
        _userRepository.Verify(x => x.DeleteAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task Delete_NotAuthenticated_ThrowsUnauthorized()
    {
        _currentUserService.SetupGet(x => x.UserId).Returns(Guid.Empty);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(401, exception.StatusCode);
    }

    [Fact]
    public async Task Delete_AcademyNotOwned_ThrowsNotFound()
    {
        _academyRepository
            .Setup(x => x.GetByIdForOwnerAsync(_academyId, _ownerUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Academy?)null);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(404, exception.StatusCode);
    }

    [Fact]
    public async Task Delete_AthleteNotFound_ThrowsNotFound()
    {
        _athleteRepository
            .Setup(x => x.GetByAcademyAndAthleteAsync(_academyId, _athleteId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((AcademyAthlete?)null);

        var handler = CreateHandler();

        var exception = await Assert.ThrowsAsync<AppException>(() =>
            handler.Handle(BuildCommand(), CancellationToken.None));

        Assert.Equal(404, exception.StatusCode);
        _unitOfWork.Verify(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    private DeleteAcademyAthleteCommandHandler CreateHandler()
        => new(
            _academyRepository.Object,
            _userRepository.Object,
            _refreshTokenRepository.Object,
            _athleteRepository.Object,
            _coachAthleteRepository.Object,
            _currentUserService.Object,
            _unitOfWork.Object,
            NullLogger<DeleteAcademyAthleteCommandHandler>.Instance);

    private DeleteAcademyAthleteCommand BuildCommand()
        => new(_academyId, _athleteId);

    private AcademyAthlete BuildAssociation()
        => new()
        {
            AcademyId = _academyId,
            AthleteId = _athleteId,
            BranchId = null,
            AssignedBy = _ownerUserId,
            Status = AthleteStatus.Invited,
            IsActive = true,
            AssignedAt = DateTime.UtcNow,
            Academy = new Academy { Id = _academyId, Name = "Dream Academy" },
            Athlete = new Athlete
            {
                Id = _athleteId,
                UserId = _userId,
                User = new User { Id = _userId, FirstName = "Ravi", LastName = "Kumar" }
            }
        };
}
