using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Coaches.DTOs;
using SPORTSGURUKUL.Application.Coaches.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class CoachAthleteRepository : ICoachAthleteRepository
{
    private readonly AppDbContext _context;

    public CoachAthleteRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<List<CoachAthlete>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.CoachAthletes
            .AsNoTracking()
            .Include(ca => ca.Athlete)
                .ThenInclude(a => a.User)
            .Include(ca => ca.Coach)
                .ThenInclude(c => c.User)
            .Include(ca => ca.Sport)
            .Where(ca => ca.AcademyId == academyId)
            .OrderBy(ca => ca.Athlete.User.FirstName)
            .ThenBy(ca => ca.Athlete.User.LastName)
            .ToListAsync(cancellationToken);

    public Task<List<CoachAthlete>> GetByCoachAndAcademyAsync(
        Guid coachId,
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.CoachAthletes
            .AsNoTracking()
            .Include(ca => ca.Athlete)
                .ThenInclude(a => a.User)
            .Include(ca => ca.Sport)
            .Where(ca => ca.CoachId == coachId && ca.AcademyId == academyId)
            .OrderBy(ca => ca.Athlete.User.FirstName)
            .ThenBy(ca => ca.Athlete.User.LastName)
            .ToListAsync(cancellationToken);

    public Task<List<CoachAthlete>> GetByAthleteAndAcademyAsync(
        Guid athleteId,
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.CoachAthletes
            .AsNoTracking()
            .Include(ca => ca.Coach)
                .ThenInclude(c => c.User)
            .Include(ca => ca.Sport)
            .Where(ca => ca.AthleteId == athleteId && ca.AcademyId == academyId)
            .OrderBy(ca => ca.Coach.User.FirstName)
            .ThenBy(ca => ca.Coach.User.LastName)
            .ToListAsync(cancellationToken);

    public Task<List<CoachAthlete>> GetByAthleteAsync(
        Guid athleteId,
        CancellationToken cancellationToken = default)
        => _context.CoachAthletes
            .AsNoTracking()
            .Include(ca => ca.Coach)
                .ThenInclude(c => c.User)
            .Include(ca => ca.Sport)
            .Where(ca => ca.AthleteId == athleteId)
            .OrderBy(ca => ca.Coach.User.FirstName)
            .ThenBy(ca => ca.Coach.User.LastName)
            .ToListAsync(cancellationToken);

    public Task ReplaceCoachMappingsAsync(
        Guid coachId,
        Guid academyId,
        IEnumerable<SportAthleteAssignment> assignments,
        Guid assignedBy,
        CancellationToken cancellationToken = default)
        => ReplaceMappingsAsync(
            _context.CoachAthletes.Where(ca => ca.CoachId == coachId && ca.AcademyId == academyId),
            BuildCoachMappings(coachId, academyId, assignments, assignedBy),
            cancellationToken);

    public Task ReplaceAthleteMappingsAsync(
        Guid athleteId,
        Guid academyId,
        IEnumerable<SportCoachAssignment> assignments,
        Guid assignedBy,
        CancellationToken cancellationToken = default)
        => ReplaceMappingsAsync(
            _context.CoachAthletes.Where(ca => ca.AthleteId == athleteId && ca.AcademyId == academyId),
            BuildAthleteMappings(athleteId, academyId, assignments, assignedBy),
            cancellationToken);

    private async Task ReplaceMappingsAsync(
        IQueryable<CoachAthlete> existing,
        IEnumerable<CoachAthlete> replacements,
        CancellationToken cancellationToken)
    {
        await existing.ExecuteDeleteAsync(cancellationToken);

        var rows = replacements.ToList();
        if (rows.Count > 0)
        {
            await _context.CoachAthletes.AddRangeAsync(rows, cancellationToken);
        }
    }

    private static List<CoachAthlete> BuildCoachMappings(
        Guid coachId,
        Guid academyId,
        IEnumerable<SportAthleteAssignment> assignments,
        Guid assignedBy)
    {
        var now = DateTime.UtcNow;
        var seen = new HashSet<(Guid SportId, Guid AthleteId)>();

        return assignments
            .SelectMany(a => a.AthleteIds
                .Distinct()
                .Select(athleteId => (a.SportId, athleteId)))
            .Where(pair => seen.Add(pair))
            .Select(pair => new CoachAthlete
            {
                CoachId = coachId,
                AthleteId = pair.athleteId,
                SportId = pair.SportId,
                AcademyId = academyId,
                AssignedBy = assignedBy,
                AssignedAt = now
            })
            .ToList();
    }

    private static List<CoachAthlete> BuildAthleteMappings(
        Guid athleteId,
        Guid academyId,
        IEnumerable<SportCoachAssignment> assignments,
        Guid assignedBy)
    {
        var now = DateTime.UtcNow;
        var seen = new HashSet<(Guid SportId, Guid CoachId)>();

        return assignments
            .SelectMany(a => a.CoachIds
                .Distinct()
                .Select(coachId => (a.SportId, coachId)))
            .Where(pair => seen.Add(pair))
            .Select(pair => new CoachAthlete
            {
                CoachId = pair.coachId,
                AthleteId = athleteId,
                SportId = pair.SportId,
                AcademyId = academyId,
                AssignedBy = assignedBy,
                AssignedAt = now
            })
            .ToList();
    }

    public Task RemoveByCoachAsync(
        Guid coachId,
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.CoachAthletes
            .Where(ca => ca.CoachId == coachId && ca.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);

    public Task RemoveByAthleteAsync(
        Guid athleteId,
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.CoachAthletes
            .Where(ca => ca.AthleteId == athleteId && ca.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);

    public Task<List<CoachAthlete>> GetByCoachAsync(
        Guid coachId,
        CancellationToken cancellationToken = default)
        => _context.CoachAthletes
            .AsNoTracking()
            .Include(ca => ca.Athlete)
                .ThenInclude(a => a.User)
            .Include(ca => ca.Athlete)
                .ThenInclude(a => a.Sports)
                    .ThenInclude(s => s.Sport)
            .Include(ca => ca.Sport)
            .Include(ca => ca.Academy)
            .Where(ca => ca.CoachId == coachId)
            .OrderBy(ca => ca.Athlete.User.FirstName)
            .ThenBy(ca => ca.Athlete.User.LastName)
            .ToListAsync(cancellationToken);
}
