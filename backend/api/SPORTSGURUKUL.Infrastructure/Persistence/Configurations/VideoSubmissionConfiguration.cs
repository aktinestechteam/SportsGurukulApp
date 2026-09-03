using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class VideoSubmissionConfiguration : IEntityTypeConfiguration<VideoSubmission>
{
    public void Configure(EntityTypeBuilder<VideoSubmission> builder)
    {
        builder.ToTable("VideoSubmissions");

        builder.HasKey(v => v.Id);

        builder.Property(v => v.Title)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(v => v.Message)
            .HasMaxLength(1000);

        builder.Property(v => v.S3Key)
            .HasMaxLength(500)
            .IsRequired();

        builder.Property(v => v.ThumbnailS3Key)
            .HasMaxLength(500);

        builder.Property(v => v.DurationSeconds)
            .IsRequired();

        builder.Property(v => v.FileSizeBytes)
            .IsRequired();

        builder.Property(v => v.Status)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(v => v.IsDeleted)
            .IsRequired();

        builder.Property(v => v.CreatedAt)
            .IsRequired();

        builder.Property(v => v.UpdatedAt)
            .IsRequired();

        builder.HasIndex(v => v.AthleteId)
            .HasDatabaseName("IX_VideoSubmissions_AthleteId");

        builder.HasIndex(v => v.SportId)
            .HasDatabaseName("IX_VideoSubmissions_SportId");

        builder.HasIndex(v => v.Status)
            .HasDatabaseName("IX_VideoSubmissions_Status");

        builder.HasOne(v => v.Athlete)
            .WithMany()
            .HasForeignKey(v => v.AthleteId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(v => v.Sport)
            .WithMany()
            .HasForeignKey(v => v.SportId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(v => v.Comments)
            .WithOne(c => c.VideoSubmission)
            .HasForeignKey(c => c.VideoSubmissionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(v => v.Views)
            .WithOne(vw => vw.VideoSubmission)
            .HasForeignKey(vw => vw.VideoSubmissionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
