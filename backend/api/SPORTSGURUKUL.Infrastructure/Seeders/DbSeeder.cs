using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SPORTSGURUKUL.Domain.Constants;
using SPORTSGURUKUL.Domain.Entities;
using SPORTSGURUKUL.Infrastructure.Persistence;

namespace SPORTSGURUKUL.Infrastructure.Seeders;

public class DbSeeder
{
    private readonly AppDbContext _context;
    private readonly ILogger<DbSeeder> _logger;

    public DbSeeder(AppDbContext context, ILogger<DbSeeder> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        if (!await _context.Roles.AnyAsync(cancellationToken))
        {
            var now = DateTime.UtcNow;
            var roles = RoleNames.All.Select((name, index) => new Role
            {
                Id = Guid.NewGuid(),
                Name = name,
                Description = $"System role: {name}",
                IsSystemRole = true,
                CreatedAt = now
            }).ToList();

            _context.Roles.AddRange(roles);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Seeded {RoleCount} system roles", roles.Count);
        }
    }
}
