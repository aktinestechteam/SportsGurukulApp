using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Domain.Constants;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class RoleRepository : IRoleRepository
{
    private readonly AppDbContext _context;

    public RoleRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<Role?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
        => _context.Roles.FirstOrDefaultAsync(r => r.Name == name, cancellationToken);

    public Task<Role?> GetAppUserRoleAsync(CancellationToken cancellationToken = default)
        => GetByNameAsync(RoleNames.AppUser, cancellationToken);
}
