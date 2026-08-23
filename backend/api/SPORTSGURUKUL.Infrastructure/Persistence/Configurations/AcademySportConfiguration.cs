using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademySportConfiguration : IEntityTypeConfiguration<AcademySport>
{
    public void Configure(EntityTypeBuilder<AcademySport> builder)
    {
        builder.ToTable("AcademySports");

        builder.HasKey(s => s.Id);

        builder.Property(s => s.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(s => s.CreatedAt)
            .IsRequired();

        builder.HasIndex(s => s.AcademyId)
            .HasDatabaseName("IX_AcademySports_AcademyId");
    }
}
