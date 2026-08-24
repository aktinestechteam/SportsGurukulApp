using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Batches.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class BatchRepository : IBatchRepository
{
    private readonly AppDbContext _context;

    public BatchRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<List<Batch>> GetByAcademyAsync(
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.Batches
            .AsNoTracking()
            .Include(b => b.Sport)
            .Include(b => b.Slots)
            .Include(b => b.CoachAssociations)
                .ThenInclude(bc => bc.Coach)
                    .ThenInclude(c => c.User)
            .Include(b => b.CoachAssociations)
                .ThenInclude(bc => bc.Coach)
                    .ThenInclude(c => c.Sports)
                        .ThenInclude(cs => cs.Sport)
            .Include(b => b.AthleteAssociations)
                .ThenInclude(ba => ba.Athlete)
                    .ThenInclude(a => a.User)
            .Include(b => b.AthleteAssociations)
                .ThenInclude(ba => ba.Athlete)
                    .ThenInclude(a => a.Sports)
                        .ThenInclude(as2 => as2.Sport)
            .Where(b => b.AcademyId == academyId)
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync(cancellationToken);

    public Task<Batch?> GetByIdForOwnerAsync(
        Guid batchId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default)
        => _context.Batches
            .Include(b => b.Sport)
            .Include(b => b.Slots)
            .Include(b => b.CoachAssociations)
                .ThenInclude(bc => bc.Coach)
                    .ThenInclude(c => c.User)
            .Include(b => b.CoachAssociations)
                .ThenInclude(bc => bc.Coach)
                    .ThenInclude(c => c.Sports)
                        .ThenInclude(cs => cs.Sport)
            .Include(b => b.AthleteAssociations)
                .ThenInclude(ba => ba.Athlete)
                    .ThenInclude(a => a.User)
            .Include(b => b.AthleteAssociations)
                .ThenInclude(ba => ba.Athlete)
                    .ThenInclude(a => a.Sports)
                        .ThenInclude(as2 => as2.Sport)
            .FirstOrDefaultAsync(
                b => b.Id == batchId &&
                     b.Academy.OwnerUserId == ownerUserId,
                cancellationToken);

    public async Task AddAsync(Batch batch, CancellationToken cancellationToken = default)
        => await _context.Batches.AddAsync(batch, cancellationToken);

    public async Task DeleteChildrenAsync(
        Guid batchId,
        CancellationToken cancellationToken = default)
    {
        await _context.BatchScheduleSlots
            .Where(s => s.BatchId == batchId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.BatchCoaches
            .Where(bc => bc.BatchId == batchId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.BatchAthletes
            .Where(ba => ba.BatchId == batchId)
            .ExecuteDeleteAsync(cancellationToken);
    }

    public Task DeleteByIdAsync(Guid batchId, CancellationToken cancellationToken = default)
        => _context.Batches
            .Where(b => b.Id == batchId)
            .ExecuteDeleteAsync(cancellationToken);

    public async Task RemoveCoachFromBatchesAsync(
        Guid coachId,
        Guid academyId,
        CancellationToken cancellationToken = default)
    {
        var batchIds = await _context.Batches
            .Where(b => b.AcademyId == academyId)
            .Select(b => b.Id)
            .ToListAsync(cancellationToken);

        await _context.BatchCoaches
            .Where(bc => batchIds.Contains(bc.BatchId) && bc.CoachId == coachId)
            .ExecuteDeleteAsync(cancellationToken);
    }

    public async Task RemoveAthleteFromBatchesAsync(
        Guid athleteId,
        Guid academyId,
        CancellationToken cancellationToken = default)
    {
        var batchIds = await _context.Batches
            .Where(b => b.AcademyId == academyId)
            .Select(b => b.Id)
            .ToListAsync(cancellationToken);

        await _context.BatchAthletes
            .Where(ba => batchIds.Contains(ba.BatchId) && ba.AthleteId == athleteId)
            .ExecuteDeleteAsync(cancellationToken);
    }

    public Task<List<Batch>> GetByCoachAsync(
        Guid coachId,
        CancellationToken cancellationToken = default)
        => _context.Batches
            .AsNoTracking()
            .Include(b => b.Academy)
            .Include(b => b.Sport)
            .Include(b => b.Slots)
            .Include(b => b.CoachAssociations)
                .ThenInclude(bc => bc.Coach)
                    .ThenInclude(c => c.User)
            .Include(b => b.AthleteAssociations)
                .ThenInclude(ba => ba.Athlete)
                    .ThenInclude(a => a.User)
            .Include(b => b.AthleteAssociations)
                .ThenInclude(ba => ba.Athlete)
                    .ThenInclude(a => a.Sports)
                        .ThenInclude(s => s.Sport)
            .Where(b => b.CoachAssociations.Any(bc => bc.CoachId == coachId))
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync(cancellationToken);

    public void Detach(Batch batch)
    {
        var entry = _context.Entry(batch);
        if (entry.State != EntityState.Detached)
        {
            entry.State = EntityState.Detached;
        }
    }

    public void ClearTracker()
    {
        _context.ChangeTracker.Clear();
    }
}
