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
            .Where(a => a.OwnerUserId == ownerUserId)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(cancellationToken);

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
}
