using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademyAthleteConfiguration : IEntityTypeConfiguration<AcademyAthlete>
{
    public void Configure(EntityTypeBuilder<AcademyAthlete> builder)
    {
        builder.ToTable("AcademyAthletes");

        builder.HasKey(a => new { a.AcademyId, a.AthleteId });

        builder.Property(a => a.Status)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(a => a.IsActive)
            .IsRequired();

        builder.Property(a => a.AssignedAt)
            .IsRequired();

        builder.HasIndex(a => a.AthleteId)
            .HasDatabaseName("IX_AcademyAthletes_AthleteId");

        builder.HasIndex(a => a.BranchId)
            .HasDatabaseName("IX_AcademyAthletes_BranchId");

        builder.HasOne(a => a.Academy)
            .WithMany(ac => ac.AthleteAssociations)
            .HasForeignKey(a => a.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(a => a.Athlete)
            .WithMany(at => at.AcademyAssociations)
            .HasForeignKey(a => a.AthleteId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(a => a.Branch)
            .WithMany(b => b.AthleteAssociations)
            .HasForeignKey(a => a.BranchId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
