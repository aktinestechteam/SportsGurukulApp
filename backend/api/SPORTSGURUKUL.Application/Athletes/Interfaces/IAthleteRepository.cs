using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Application.Athletes.Interfaces;

public interface IAthleteRepository
{
    /// <summary>
    /// Loads the academy athlete associations for the given academy including
    /// the athlete profile, user identity, branch and sport assignments.
    /// </summary>
    Task<List<AcademyAthlete>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default);

    Task AddAsync(Athlete athlete, CancellationToken cancellationToken = default);

    Task AddAssociationAsync(AcademyAthlete association, CancellationToken cancellationToken = default);

    /// <summary>
    /// Loads the athlete association for a specific academy/athlete pair
    /// including the academy, branch, athlete profile, user identity and sport
    /// assignments.
    /// </summary>
    Task<AcademyAthlete?> GetByAcademyAndAthleteAsync(
        Guid academyId,
        Guid athleteId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Loads the athlete association for a specific academy/athlete pair
    /// without tracking, including the academy, branch, athlete profile, user
    /// identity and sport assignments.
    /// </summary>
    Task<AcademyAthlete?> GetByAcademyAndAthleteAsNoTrackingAsync(
        Guid academyId,
        Guid athleteId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns true when the athlete is associated with any academy other than
    /// the given one.
    /// </summary>
    Task<bool> HasOtherAssociationsAsync(
        Guid athleteId,
        Guid exceptAcademyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes the athlete's current sport assignments and replaces them with
    /// the given set.
    /// </summary>
    Task ReplaceSportsAsync(
        Athlete athlete,
        IEnumerable<AthleteSport> newSports,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes the academy/athlete association row.
    /// </summary>
    Task RemoveAssociationAsync(
        Guid academyId,
        Guid athleteId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes every athlete sport assignment whose sport belongs to
    /// the given academy's sport set.
    /// </summary>
    Task RemoveSportsAsync(
        IEnumerable<Guid> sportIds,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Permanently removes the athlete profile and all of its sport assignments.
    /// </summary>
    Task RemoveAthleteAsync(Guid athleteId, CancellationToken cancellationToken = default);
}
