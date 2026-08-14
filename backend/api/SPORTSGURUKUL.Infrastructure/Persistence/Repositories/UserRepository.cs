using Microsoft.EntityFrameworkCore;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Repositories;

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;

    public UserRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<User?> GetByIdAsync(Guid userId, CancellationToken cancellationToken = default)
        => _context.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

    public Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken cancellationToken = default)
        => _context.Users.FirstOrDefaultAsync(u => u.NormalizedEmail == normalizedEmail, cancellationToken);

    public Task<User?> GetByEmailWithRolesAsync(string normalizedEmail, CancellationToken cancellationToken = default)
        => _context.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.NormalizedEmail == normalizedEmail, cancellationToken);

    public Task<User?> GetByIdWithRolesAsync(Guid userId, CancellationToken cancellationToken = default)
        => _context.Users
            .Include(u => u.UserRoles)
            .ThenInclude(ur => ur.Role)
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

    public Task<bool> EmailExistsAsync(string normalizedEmail, CancellationToken cancellationToken = default)
        => _context.Users.AnyAsync(u => u.NormalizedEmail == normalizedEmail, cancellationToken);

    public Task<bool> MobileNumberExistsAsync(string normalizedMobileNumber, CancellationToken cancellationToken = default)
        => _context.Users.AnyAsync(u => u.NormalizedMobileNumber == normalizedMobileNumber, cancellationToken);

    public Task<bool> EmailExistsExcludingAsync(string normalizedEmail, Guid excludeUserId, CancellationToken cancellationToken = default)
        => _context.Users.AnyAsync(
            u => u.NormalizedEmail == normalizedEmail && u.Id != excludeUserId,
            cancellationToken);

    public Task<bool> MobileNumberExistsExcludingAsync(string normalizedMobileNumber, Guid excludeUserId, CancellationToken cancellationToken = default)
        => _context.Users.AnyAsync(
            u => u.NormalizedMobileNumber == normalizedMobileNumber && u.Id != excludeUserId,
            cancellationToken);

    public Task<bool> PublicUserIdExistsAsync(string publicUserId, CancellationToken cancellationToken = default)
        => _context.Users.AnyAsync(u => u.PublicUserId == publicUserId, cancellationToken);

    public async Task AddAsync(User user, CancellationToken cancellationToken = default)
        => await _context.Users.AddAsync(user, cancellationToken);

    public Task UpdateAsync(User user, CancellationToken cancellationToken = default)
    {
        _context.Users.Update(user);
        return Task.CompletedTask;
    }

    public async Task<List<string>> GetRoleNamesAsync(Guid userId, CancellationToken cancellationToken = default)
        => await _context.UserRoles
            .Where(ur => ur.UserId == userId && ur.IsActive)
            .Select(ur => ur.Role.Name)
            .ToListAsync(cancellationToken);

    public Task RemoveRolesAsync(Guid userId, CancellationToken cancellationToken = default)
        => _context.UserRoles
            .Where(ur => ur.UserId == userId)
            .ExecuteDeleteAsync(cancellationToken);

    public Task DeleteAsync(Guid userId, CancellationToken cancellationToken = default)
        => _context.Users
            .Where(u => u.Id == userId)
            .ExecuteDeleteAsync(cancellationToken);
}
