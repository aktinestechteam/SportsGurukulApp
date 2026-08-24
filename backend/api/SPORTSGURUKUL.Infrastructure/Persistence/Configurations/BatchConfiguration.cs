using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class BatchConfiguration : IEntityTypeConfiguration<Batch>
{
    public void Configure(EntityTypeBuilder<Batch> builder)
    {
        builder.ToTable("Batches");

        builder.HasKey(b => b.Id);

        builder.Property(b => b.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(b => b.Description)
            .HasMaxLength(2000);

        builder.Property(b => b.CreatedAt)
            .IsRequired();

        builder.Property(b => b.UpdatedAt)
            .IsRequired();

        builder.HasIndex(b => b.AcademyId)
            .HasDatabaseName("IX_Batches_AcademyId");

        builder.HasIndex(b => new { b.AcademyId, b.Name })
            .IsUnique()
            .HasDatabaseName("IX_Batches_AcademyId_Name");

        builder.HasOne(b => b.Academy)
            .WithMany(a => a.Batches)
            .HasForeignKey(b => b.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(b => b.Sport)
            .WithMany()
            .HasForeignKey(b => b.SportId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(b => b.Slots)
            .WithOne(s => s.Batch)
            .HasForeignKey(s => s.BatchId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(b => b.CoachAssociations)
            .WithOne(bc => bc.Batch)
            .HasForeignKey(bc => bc.BatchId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(b => b.AthleteAssociations)
            .WithOne(ba => ba.Batch)
            .HasForeignKey(ba => ba.BatchId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
