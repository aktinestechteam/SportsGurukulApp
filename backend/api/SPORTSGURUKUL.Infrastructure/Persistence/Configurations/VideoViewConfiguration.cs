using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class VideoViewConfiguration : IEntityTypeConfiguration<VideoView>
{
    public void Configure(EntityTypeBuilder<VideoView> builder)
    {
        builder.ToTable("VideoViews");

        builder.HasKey(v => v.Id);

        builder.Property(v => v.ViewedAt)
            .IsRequired();

        builder.HasIndex(v => v.VideoSubmissionId)
            .HasDatabaseName("IX_VideoViews_VideoSubmissionId");

        builder.HasIndex(v => v.UserId)
            .HasDatabaseName("IX_VideoViews_UserId");

        builder.HasOne(v => v.VideoSubmission)
            .WithMany(vw => vw.Views)
            .HasForeignKey(v => v.VideoSubmissionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(v => v.User)
            .WithMany()
            .HasForeignKey(v => v.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
