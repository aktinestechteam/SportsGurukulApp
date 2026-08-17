using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class CoachAthleteConfiguration : IEntityTypeConfiguration<CoachAthlete>
{
    public void Configure(EntityTypeBuilder<CoachAthlete> builder)
    {
        builder.ToTable("CoachAthletes");

        builder.HasKey(ca => new { ca.CoachId, ca.AthleteId, ca.AcademyId });

        builder.Property(ca => ca.AssignedAt)
            .IsRequired();

        builder.HasIndex(ca => ca.AthleteId)
            .HasDatabaseName("IX_CoachAthletes_AthleteId");

        builder.HasIndex(ca => ca.AcademyId)
            .HasDatabaseName("IX_CoachAthletes_AcademyId");

        builder.HasOne(ca => ca.Coach)
            .WithMany(c => c.AthleteMappings)
            .HasForeignKey(ca => ca.CoachId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(ca => ca.Athlete)
            .WithMany(a => a.CoachMappings)
            .HasForeignKey(ca => ca.AthleteId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(ca => ca.Academy)
            .WithMany(a => a.CoachAthleteMappings)
            .HasForeignKey(ca => ca.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
