using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AthleteSportConfiguration : IEntityTypeConfiguration<AthleteSport>
{
    public void Configure(EntityTypeBuilder<AthleteSport> builder)
    {
        builder.ToTable("AthleteSports");

        builder.HasKey(a => new { a.AthleteId, a.SportId });

        builder.Property(a => a.IsPrimary)
            .IsRequired();

        builder.Property(a => a.CreatedAt)
            .IsRequired();

        builder.HasIndex(a => a.SportId)
            .HasDatabaseName("IX_AthleteSports_SportId");

        builder.HasOne(a => a.Athlete)
            .WithMany(at => at.Sports)
            .HasForeignKey(a => a.AthleteId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(a => a.Sport)
            .WithMany(s => s.AthleteSports)
            .HasForeignKey(a => a.SportId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
