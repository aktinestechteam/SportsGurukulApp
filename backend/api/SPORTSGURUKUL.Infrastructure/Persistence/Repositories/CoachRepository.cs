using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class CoachRepository : ICoachRepository
{
    private readonly AppDbContext _context;

    public CoachRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<List<AcademyCoach>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.AcademyCoaches
            .AsNoTracking()
            .Include(a => a.Academy)
            .Include(a => a.Branch)
            .Include(a => a.Coach)
                .ThenInclude(c => c.User)
            .Include(a => a.Coach)
                .ThenInclude(c => c.Sports)
                    .ThenInclude(cs => cs.Sport)
            .Where(a => a.AcademyId == academyId)
            .OrderBy(a => a.Coach.User.FirstName)
            .ThenBy(a => a.Coach.User.LastName)
            .ToListAsync(cancellationToken);

    public async Task AddAsync(Coach coach, CancellationToken cancellationToken = default)
        => await _context.Coaches.AddAsync(coach, cancellationToken);

    public async Task AddAssociationAsync(AcademyCoach association, CancellationToken cancellationToken = default)
        => await _context.AcademyCoaches.AddAsync(association, cancellationToken);

    public Task<AcademyCoach?> GetByAcademyAndCoachAsync(
        Guid academyId,
        Guid coachId,
        CancellationToken cancellationToken = default)
        => _context.AcademyCoaches
            .Include(a => a.Academy)
            .Include(a => a.Branch)
            .Include(a => a.Coach)
                .ThenInclude(c => c.User)
            .Include(a => a.Coach)
                .ThenInclude(c => c.Sports)
                    .ThenInclude(cs => cs.Sport)
            .FirstOrDefaultAsync(
                a => a.AcademyId == academyId && a.CoachId == coachId,
                cancellationToken);

    public Task<AcademyCoach?> GetByAcademyAndCoachAsNoTrackingAsync(
        Guid academyId,
        Guid coachId,
        CancellationToken cancellationToken = default)
        => _context.AcademyCoaches
            .AsNoTracking()
            .Include(a => a.Academy)
            .Include(a => a.Branch)
            .Include(a => a.Coach)
                .ThenInclude(c => c.User)
            .Include(a => a.Coach)
                .ThenInclude(c => c.Sports)
                    .ThenInclude(cs => cs.Sport)
            .FirstOrDefaultAsync(
                a => a.AcademyId == academyId && a.CoachId == coachId,
                cancellationToken);

    public Task<bool> HasOtherAssociationsAsync(
        Guid coachId,
        Guid exceptAcademyId,
        CancellationToken cancellationToken = default)
        => _context.AcademyCoaches.AnyAsync(
            a => a.CoachId == coachId && a.AcademyId != exceptAcademyId,
            cancellationToken);

    public Task ReplaceSportsAsync(
        Coach coach,
        IEnumerable<CoachSport> newSports,
        CancellationToken cancellationToken = default)
    {
        _context.CoachSports.RemoveRange(coach.Sports);
        coach.Sports.Clear();

        foreach (var sport in newSports)
        {
            sport.CoachId = coach.Id;
            _context.CoachSports.Add(sport);
            coach.Sports.Add(sport);
        }

        return Task.CompletedTask;
    }

    public Task RemoveAssociationAsync(
        Guid academyId,
        Guid coachId,
        CancellationToken cancellationToken = default)
        => _context.AcademyCoaches
            .Where(a => a.AcademyId == academyId && a.CoachId == coachId)
            .ExecuteDeleteAsync(cancellationToken);

    public Task RemoveSportsAsync(
        IEnumerable<Guid> sportIds,
        CancellationToken cancellationToken = default)
        => _context.CoachSports
            .Where(c => sportIds.Contains(c.SportId))
            .ExecuteDeleteAsync(cancellationToken);

    public Task<List<CoachSport>> GetSportsBySportIdsAsync(
        IEnumerable<Guid> sportIds,
        CancellationToken cancellationToken = default)
        => _context.CoachSports
            .AsNoTracking()
            .Where(c => sportIds.Contains(c.SportId))
            .ToListAsync(cancellationToken);

    public Task AddSportAsync(
        Guid coachId,
        Guid sportId,
        string? specialization,
        CancellationToken cancellationToken = default)
    {
        _context.CoachSports.Add(new CoachSport
        {
            CoachId = coachId,
            SportId = sportId,
            Specialization = specialization,
            CreatedAt = DateTime.UtcNow
        });

        return Task.CompletedTask;
    }

    public async Task RemoveCoachAsync(Guid coachId, CancellationToken cancellationToken = default)
    {
        await _context.CoachSports
            .Where(cs => cs.CoachId == coachId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.Coaches
            .Where(c => c.Id == coachId)
            .ExecuteDeleteAsync(cancellationToken);
    }

    public Task<Coach?> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
        => _context.Coaches
            .AsNoTracking()
            .Include(c => c.User)
            .Include(c => c.AcademyAssociations)
                .ThenInclude(a => a.Academy)
                    .ThenInclude(ac => ac.Sports)
            .Include(c => c.Sports)
                .ThenInclude(cs => cs.Sport)
            .FirstOrDefaultAsync(c => c.UserId == userId, cancellationToken);

    public Task<Coach?> GetByIdAsync(
        Guid coachId,
        CancellationToken cancellationToken = default)
        => _context.Coaches
            .AsNoTracking()
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Id == coachId, cancellationToken);
}
