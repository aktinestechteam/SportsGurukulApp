using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class BatchScheduleSlotConfiguration : IEntityTypeConfiguration<BatchScheduleSlot>
{
    public void Configure(EntityTypeBuilder<BatchScheduleSlot> builder)
    {
        builder.ToTable("BatchScheduleSlots");

        builder.HasKey(s => s.Id);

        builder.Property(s => s.Location)
            .HasMaxLength(200);

        builder.Property(s => s.CreatedAt)
            .IsRequired();

        builder.HasIndex(s => s.BatchId)
            .HasDatabaseName("IX_BatchScheduleSlots_BatchId");

        builder.HasOne(s => s.Batch)
            .WithMany(b => b.Slots)
            .HasForeignKey(s => s.BatchId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
