using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademyMembershipConfiguration : IEntityTypeConfiguration<AcademyMembership>
{
    public void Configure(EntityTypeBuilder<AcademyMembership> builder)
    {
        builder.ToTable("AcademyMemberships");

        builder.HasKey(m => m.Id);

        builder.Property(m => m.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(m => m.Description)
            .HasMaxLength(500);

        builder.Property(m => m.DurationDays)
            .IsRequired();

        builder.Property(m => m.Price)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(m => m.IsActive)
            .IsRequired();

        builder.Property(m => m.CreatedAt)
            .IsRequired();

        builder.Property(m => m.UpdatedAt)
            .IsRequired();

        builder.HasIndex(m => m.AcademyId)
            .HasDatabaseName("IX_AcademyMemberships_AcademyId");
    }
}
