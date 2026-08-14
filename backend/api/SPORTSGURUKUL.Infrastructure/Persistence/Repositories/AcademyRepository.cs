using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Academies.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class AcademyRepository : IAcademyRepository
{
    private readonly AppDbContext _context;

    public AcademyRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<List<Academy>> GetByOwnerAsync(Guid ownerUserId, CancellationToken cancellationToken = default)
        => _context.Academies
            .AsNoTracking()
            .Include(a => a.Branches)
            .Include(a => a.Sports)
            .Include(a => a.Facilities)
            .Include(a => a.Memberships)
            .Include(a => a.WorkingHours)
            .Include(a => a.CoachAssociations)
            .Include(a => a.AthleteAssociations)
            .Where(a => a.OwnerUserId == ownerUserId)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

    public Task<Academy?> GetByIdAsync(
        Guid academyId,
        CancellationToken cancellationToken = default)
        => _context.Academies
            .Include(a => a.Branches)
            .Include(a => a.Sports)
            .FirstOrDefaultAsync(a => a.Id == academyId, cancellationToken);

    public Task<Academy?> GetByIdForOwnerAsync(
        Guid academyId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default)
        => _context.Academies
            .Include(a => a.Branches)
            .Include(a => a.Sports)
            .Include(a => a.Facilities)
            .Include(a => a.Memberships)
            .Include(a => a.WorkingHours)
            .Include(a => a.CoachAssociations)
                .ThenInclude(ca => ca.Coach)
            .Include(a => a.AthleteAssociations)
                .ThenInclude(aa => aa.Athlete)
            .FirstOrDefaultAsync(
                a => a.Id == academyId && a.OwnerUserId == ownerUserId,
                cancellationToken);

    public Task<bool> ExistsForOwnerAsync(
        Guid academyId,
        Guid ownerUserId,
        CancellationToken cancellationToken = default)
        => _context.Academies.AnyAsync(
            a => a.Id == academyId && a.OwnerUserId == ownerUserId,
            cancellationToken);

    public async Task AddAsync(Academy academy, CancellationToken cancellationToken = default)
        => await _context.Academies.AddAsync(academy, cancellationToken);

    public Task UpdateAsync(Academy academy, CancellationToken cancellationToken = default)
    {
        _context.Entry(academy).State = EntityState.Modified;

        foreach (var branch in academy.Branches)
        {
            _context.Entry(branch).State = EntityState.Added;
        }
        foreach (var sport in academy.Sports)
        {
            _context.Entry(sport).State = EntityState.Added;
        }
        foreach (var facility in academy.Facilities)
        {
            _context.Entry(facility).State = EntityState.Added;
        }
        foreach (var membership in academy.Memberships)
        {
            _context.Entry(membership).State = EntityState.Added;
        }
        foreach (var workingHour in academy.WorkingHours)
        {
            _context.Entry(workingHour).State = EntityState.Added;
        }

        return Task.CompletedTask;
    }

    public Task DeleteAsync(Academy academy, CancellationToken cancellationToken = default)
    {
        _context.Academies.Remove(academy);
        return Task.CompletedTask;
    }

    public async Task RemoveAssociationsAsync(Guid academyId, CancellationToken cancellationToken = default)
    {
        await _context.AcademyAthletes
            .Where(a => a.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.AcademyCoaches
            .Where(c => c.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);
    }

    public async Task DeleteChildrenAsync(Guid academyId, CancellationToken cancellationToken = default)
    {
        await _context.AcademyWorkingHours
            .Where(w => w.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.AcademyMemberships
            .Where(m => m.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.AcademyFacilities
            .Where(f => f.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.AcademySports
            .Where(s => s.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);

        await _context.AcademyBranches
            .Where(b => b.AcademyId == academyId)
            .ExecuteDeleteAsync(cancellationToken);
    }

    public Task DeleteByIdAsync(Guid academyId, CancellationToken cancellationToken = default)
        => _context.Academies
            .Where(a => a.Id == academyId)
            .ExecuteDeleteAsync(cancellationToken);
}
