using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Athletes.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class AthleteRepository : IAthleteRepository
{
    private readonly AppDbContext _context;

    public AthleteRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<List<AcademyAthlete>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.AcademyAthletes
            .AsNoTracking()
            .Include(a => a.Academy)
            .Include(a => a.Branch)
            .Include(a => a.Athlete)
                .ThenInclude(at => at.User)
            .Include(a => a.Athlete)
                .ThenInclude(at => at.Sports)
                    .ThenInclude(aa => aa.Sport)
            .Where(a => a.AcademyId == academyId)
            .OrderBy(a => a.Athlete.User.FirstName)
            .ThenBy(a => a.Athlete.User.LastName)
            .ToListAsync(cancellationToken);

    public async Task AddAsync(Athlete athlete, CancellationToken cancellationToken = default)
        => await _context.Athletes.AddAsync(athlete, cancellationToken);

    public async Task AddAssociationAsync(AcademyAthlete association, CancellationToken cancellationToken = default)
        => await _context.AcademyAthletes.AddAsync(association, cancellationToken);

    public Task<AcademyAthlete?> GetByAcademyAndAthleteAsync(
        Guid academyId,
        Guid athleteId,
        CancellationToken cancellationToken = default)
        => _context.AcademyAthletes
            .Include(a => a.Academy)
            .Include(a => a.Branch)
            .Include(a => a.Athlete)
                .ThenInclude(at => at.User)
            .Include(a => a.Athlete)
                .ThenInclude(at => at.Sports)
                    .ThenInclude(aa => aa.Sport)
            .FirstOrDefaultAsync(
                a => a.AcademyId == academyId && a.AthleteId == athleteId,
                cancellationToken);

    public Task<AcademyAthlete?> GetByAcademyAndAthleteAsNoTrackingAsync(
        Guid academyId,
        Guid athleteId,
        CancellationToken cancellationToken = default)
        => _context.AcademyAthletes
            .AsNoTracking()
            .Include(a => a.Academy)
            .Include(a => a.Branch)
            .Include(a => a.Athlete)
                .ThenInclude(at => at.User)
            .Include(a => a.Athlete)
                .ThenInclude(at => at.Sports)
                    .ThenInclude(aa => aa.Sport)
            .FirstOrDefaultAsync(
                a => a.AcademyId == academyId && a.AthleteId == athleteId,
                cancellationToken);

    public Task<bool> HasOtherAssociationsAsync(
        Guid athleteId,
        Guid exceptAcademyId,
        CancellationToken cancellationToken = default)
        => _context.AcademyAthletes.AnyAsync(
            a => a.AthleteId == athleteId && a.AcademyId != exceptAcademyId,
            cancellationToken);

    public Task ReplaceSportsAsync(
        Athlete athlete,
        IEnumerable<AthleteSport> newSports,
        CancellationToken cancellationToken = default)
    {
        _context.AthleteSports.RemoveRange(athlete.Sports);
        athlete.Sports.Clear();

        foreach (var sport in newSports)
        {
            sport.AthleteId = athlete.Id;
            _context.AthleteSports.Add(sport);
            athlete.Sports.Add(sport);
        }

        return Task.CompletedTask;
    }

    public Task RemoveAssociationAsync(
        Guid academyId,
        Guid athleteId,
        CancellationToken cancellationToken = default)
        => _context.AcademyAthletes
            .Where(a => a.AcademyId == academyId && a.AthleteId == athleteId)
            .ExecuteDeleteAsync(cancellationToken);

    public Task RemoveSportsAsync(
        IEnumerable<Guid> sportIds,
        CancellationToken cancellationToken = default)
        => _context.AthleteSports
            .Where(a => sportIds.Contains(a.SportId))
            .ExecuteDeleteAsync(cancellationToken);

    public async Task RemoveAthleteAsync(Guid athleteId, CancellationToken cancellationToken = default)
    {
        await _context.AthleteSports
            .Where(aa => aa.AthleteId == athleteId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.Athletes
            .Where(a => a.Id == athleteId)
            .ExecuteDeleteAsync(cancellationToken);
    }
}
