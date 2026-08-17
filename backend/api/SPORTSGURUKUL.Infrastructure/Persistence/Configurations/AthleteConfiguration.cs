using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AthleteConfiguration : IEntityTypeConfiguration<Athlete>
{
    public void Configure(EntityTypeBuilder<Athlete> builder)
    {
        builder.ToTable("Athletes");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.DateOfBirth)
            .IsRequired();

        builder.Property(a => a.Gender)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(a => a.Address)
            .HasMaxLength(500);

        builder.Property(a => a.EmergencyContact)
            .HasMaxLength(30);

        builder.Property(a => a.ProfilePhotoUrl)
            .HasMaxLength(500);

        builder.Property(a => a.AgeGroup)
            .HasMaxLength(20);

        builder.Property(a => a.CreatedAt)
            .IsRequired();

        builder.Property(a => a.UpdatedAt)
            .IsRequired();

        builder.HasOne(a => a.User)
            .WithMany(u => u.Athletes)
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(a => a.AcademyAssociations)
            .WithOne(aa => aa.Athlete)
            .HasForeignKey(aa => aa.AthleteId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(a => a.Sports)
            .WithOne(aa => aa.Athlete)
            .HasForeignKey(aa => aa.AthleteId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
