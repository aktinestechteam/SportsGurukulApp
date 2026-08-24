using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class BatchCoachConfiguration : IEntityTypeConfiguration<BatchCoach>
{
    public void Configure(EntityTypeBuilder<BatchCoach> builder)
    {
        builder.ToTable("BatchCoaches");

        builder.HasKey(bc => new { bc.BatchId, bc.CoachId });

        builder.Property(bc => bc.AssignedAt)
            .IsRequired();

        builder.HasIndex(bc => bc.CoachId)
            .HasDatabaseName("IX_BatchCoaches_CoachId");

        builder.HasOne(bc => bc.Batch)
            .WithMany(b => b.CoachAssociations)
            .HasForeignKey(bc => bc.BatchId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(bc => bc.Coach)
            .WithMany()
            .HasForeignKey(bc => bc.CoachId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
