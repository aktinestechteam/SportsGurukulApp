using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademyBranchConfiguration : IEntityTypeConfiguration<AcademyBranch>
{
    public void Configure(EntityTypeBuilder<AcademyBranch> builder)
    {
        builder.ToTable("AcademyBranches");

        builder.HasKey(b => b.Id);

        builder.Property(b => b.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(b => b.Address)
            .HasMaxLength(300);

        builder.Property(b => b.City)
            .HasMaxLength(100);

        builder.Property(b => b.State)
            .HasMaxLength(100);

        builder.Property(b => b.Country)
            .HasMaxLength(100);

        builder.Property(b => b.PostalCode)
            .HasMaxLength(20);

        builder.Property(b => b.ContactEmail)
            .HasMaxLength(256);

        builder.Property(b => b.ContactPhone)
            .HasMaxLength(30);

        builder.Property(b => b.IsMain)
            .IsRequired();

        builder.Property(b => b.CreatedAt)
            .IsRequired();

        builder.Property(b => b.UpdatedAt)
            .IsRequired();

        builder.HasIndex(b => b.AcademyId)
            .HasDatabaseName("IX_AcademyBranches_AcademyId");
    }
}
