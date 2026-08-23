using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademyCoachConfiguration : IEntityTypeConfiguration<AcademyCoach>
{
    public void Configure(EntityTypeBuilder<AcademyCoach> builder)
    {
        builder.ToTable("AcademyCoaches");

        builder.HasKey(a => new { a.AcademyId, a.CoachId });

        builder.Property(a => a.Status)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(a => a.IsActive)
            .IsRequired();

        builder.Property(a => a.AssignedAt)
            .IsRequired();

        builder.HasIndex(a => a.CoachId)
            .HasDatabaseName("IX_AcademyCoaches_CoachId");

        builder.HasIndex(a => a.BranchId)
            .HasDatabaseName("IX_AcademyCoaches_BranchId");

        builder.HasOne(a => a.Academy)
            .WithMany(ac => ac.CoachAssociations)
            .HasForeignKey(a => a.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.Coach)
            .WithMany(c => c.AcademyAssociations)
            .HasForeignKey(a => a.CoachId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(a => a.Branch)
            .WithMany(b => b.CoachAssociations)
            .HasForeignKey(a => a.BranchId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
