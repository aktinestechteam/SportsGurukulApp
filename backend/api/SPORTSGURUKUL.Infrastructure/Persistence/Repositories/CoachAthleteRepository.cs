using Microsoft.EntityFrameworkCore;
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
            .Where(ca => ca.AthleteId == athleteId && ca.AcademyId == academyId)
            .OrderBy(ca => ca.Coach.User.FirstName)
            .ThenBy(ca => ca.Coach.User.LastName)
            .ToListAsync(cancellationToken);

    public Task ReplaceCoachMappingsAsync(
        Guid coachId,
        Guid academyId,
        IEnumerable<Guid> athleteIds,
        Guid assignedBy,
        CancellationToken cancellationToken = default)
        => ReplaceMappingsAsync(
            _context.CoachAthletes.Where(ca => ca.CoachId == coachId && ca.AcademyId == academyId),
            BuildCoachMappings(coachId, academyId, athleteIds, assignedBy),
            cancellationToken);

    public Task ReplaceAthleteMappingsAsync(
        Guid athleteId,
        Guid academyId,
        IEnumerable<Guid> coachIds,
        Guid assignedBy,
        CancellationToken cancellationToken = default)
        => ReplaceMappingsAsync(
            _context.CoachAthletes.Where(ca => ca.AthleteId == athleteId && ca.AcademyId == academyId),
            BuildAthleteMappings(athleteId, academyId, coachIds, assignedBy),
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
        IEnumerable<Guid> athleteIds,
        Guid assignedBy)
    {
        var now = DateTime.UtcNow;
        var seen = new HashSet<Guid>();

        return athleteIds
            .Distinct()
            .Where(seen.Add)
            .Select(athleteId => new CoachAthlete
            {
                CoachId = coachId,
                AthleteId = athleteId,
                AcademyId = academyId,
                AssignedBy = assignedBy,
                AssignedAt = now
            })
            .ToList();
    }

    private static List<CoachAthlete> BuildAthleteMappings(
        Guid athleteId,
        Guid academyId,
        IEnumerable<Guid> coachIds,
        Guid assignedBy)
    {
        var now = DateTime.UtcNow;
        var seen = new HashSet<Guid>();

        return coachIds
            .Distinct()
            .Where(seen.Add)
            .Select(coachId => new CoachAthlete
            {
                CoachId = coachId,
                AthleteId = athleteId,
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
}
