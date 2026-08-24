using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class BatchAthleteConfiguration : IEntityTypeConfiguration<BatchAthlete>
{
    public void Configure(EntityTypeBuilder<BatchAthlete> builder)
    {
        builder.ToTable("BatchAthletes");

        builder.HasKey(ba => new { ba.BatchId, ba.AthleteId });

        builder.Property(ba => ba.AssignedAt)
            .IsRequired();

        builder.HasIndex(ba => ba.AthleteId)
            .HasDatabaseName("IX_BatchAthletes_AthleteId");

        builder.HasOne(ba => ba.Batch)
            .WithMany(b => b.AthleteAssociations)
            .HasForeignKey(ba => ba.BatchId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(ba => ba.Athlete)
            .WithMany()
            .HasForeignKey(ba => ba.AthleteId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
