using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademyFacilityConfiguration : IEntityTypeConfiguration<AcademyFacility>
{
    public void Configure(EntityTypeBuilder<AcademyFacility> builder)
    {
        builder.ToTable("AcademyFacilities");

        builder.HasKey(f => f.Id);

        builder.Property(f => f.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(f => f.Type)
            .HasMaxLength(100);

        builder.Property(f => f.Description)
            .HasMaxLength(500);

        builder.Property(f => f.IsActive)
            .IsRequired();

        builder.Property(f => f.CreatedAt)
            .IsRequired();

        builder.Property(f => f.UpdatedAt)
            .IsRequired();

        builder.HasIndex(f => f.AcademyId)
            .HasDatabaseName("IX_AcademyFacilities_AcademyId");
    }
}
