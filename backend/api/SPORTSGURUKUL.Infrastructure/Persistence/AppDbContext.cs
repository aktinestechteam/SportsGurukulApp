using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence;

public class AppDbContext : DbContext, IUnitOfWork
{
    private IDbContextTransaction? _activeTransaction;

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();
    public DbSet<EmailVerificationToken> EmailVerificationTokens => Set<EmailVerificationToken>();

    public DbSet<Academy> Academies => Set<Academy>();
    public DbSet<AcademyBranch> AcademyBranches => Set<AcademyBranch>();
    public DbSet<AcademySport> AcademySports => Set<AcademySport>();
    public DbSet<AcademyFacility> AcademyFacilities => Set<AcademyFacility>();
    public DbSet<AcademyMembership> AcademyMemberships => Set<AcademyMembership>();
    public DbSet<AcademyWorkingHour> AcademyWorkingHours => Set<AcademyWorkingHour>();

    public DbSet<Coach> Coaches => Set<Coach>();
    public DbSet<AcademyCoach> AcademyCoaches => Set<AcademyCoach>();
    public DbSet<CoachSport> CoachSports => Set<CoachSport>();
    public DbSet<CoachAthlete> CoachAthletes => Set<CoachAthlete>();

    public DbSet<Athlete> Athletes => Set<Athlete>();
    public DbSet<AcademyAthlete> AcademyAthletes => Set<AcademyAthlete>();
    public DbSet<AthleteSport> AthleteSports => Set<AthleteSport>();

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => base.SaveChangesAsync(cancellationToken);

    public async Task BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        _activeTransaction = await Database.BeginTransactionAsync(cancellationToken);
    }

    public async Task CommitAsync(CancellationToken cancellationToken = default)
    {
        if (_activeTransaction is null)
        {
            return;
        }

        await _activeTransaction.CommitAsync(cancellationToken);
        await _activeTransaction.DisposeAsync();
        _activeTransaction = null;
    }

    public async Task RollbackAsync(CancellationToken cancellationToken = default)
    {
        if (_activeTransaction is null)
        {
            return;
        }

        await _activeTransaction.RollbackAsync(cancellationToken);
        await _activeTransaction.DisposeAsync();
        _activeTransaction = null;
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
