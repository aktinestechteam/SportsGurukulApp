using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class VideoCommentConfiguration : IEntityTypeConfiguration<VideoComment>
{
    public void Configure(EntityTypeBuilder<VideoComment> builder)
    {
        builder.ToTable("VideoComments");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.Message)
            .HasMaxLength(2000);

        builder.Property(c => c.VoiceNoteS3Key)
            .HasMaxLength(500);

        builder.Property(c => c.VoiceNoteDurationSeconds);

        builder.Property(c => c.IsDeleted)
            .IsRequired();

        builder.Property(c => c.CreatedAt)
            .IsRequired();

        builder.Property(c => c.UpdatedAt)
            .IsRequired();

        builder.HasIndex(c => c.VideoSubmissionId)
            .HasDatabaseName("IX_VideoComments_VideoSubmissionId");

        builder.HasIndex(c => c.AuthorUserId)
            .HasDatabaseName("IX_VideoComments_AuthorUserId");

        builder.HasOne(c => c.VideoSubmission)
            .WithMany(v => v.Comments)
            .HasForeignKey(c => c.VideoSubmissionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.Author)
            .WithMany()
            .HasForeignKey(c => c.AuthorUserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
