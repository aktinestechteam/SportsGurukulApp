using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class CoachSportConfiguration : IEntityTypeConfiguration<CoachSport>
{
    public void Configure(EntityTypeBuilder<CoachSport> builder)
    {
        builder.ToTable("CoachSports");

        builder.HasKey(c => new { c.CoachId, c.SportId });

        builder.Property(c => c.Specialization)
            .HasMaxLength(200);

        builder.Property(c => c.CreatedAt)
            .IsRequired();

        builder.HasIndex(c => c.SportId)
            .HasDatabaseName("IX_CoachSports_SportId");

        builder.HasOne(c => c.Coach)
            .WithMany(coach => coach.Sports)
            .HasForeignKey(c => c.CoachId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(c => c.Sport)
            .WithMany(s => s.CoachSports)
            .HasForeignKey(c => c.SportId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
