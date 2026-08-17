using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademyConfiguration : IEntityTypeConfiguration<Academy>
{
    public void Configure(EntityTypeBuilder<Academy> builder)
    {
        builder.ToTable("Academies");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(a => a.Profile)
            .HasMaxLength(2000);

        builder.Property(a => a.ContactEmail)
            .HasMaxLength(256);

        builder.Property(a => a.ContactPhone)
            .HasMaxLength(30);

        builder.Property(a => a.Address)
            .HasMaxLength(300);

        builder.Property(a => a.City)
            .HasMaxLength(100);

        builder.Property(a => a.State)
            .HasMaxLength(100);

        builder.Property(a => a.Country)
            .HasMaxLength(100);

        builder.Property(a => a.PostalCode)
            .HasMaxLength(20);

        builder.Property(a => a.LogoUrl)
            .HasMaxLength(500);

        builder.Property(a => a.IsPublic)
            .IsRequired();

        builder.Property(a => a.CreatedAt)
            .IsRequired();

        builder.Property(a => a.UpdatedAt)
            .IsRequired();

        builder.HasIndex(a => a.OwnerUserId)
            .HasDatabaseName("IX_Academies_OwnerUserId");

        builder.HasOne(a => a.OwnerUser)
            .WithMany()
            .HasForeignKey(a => a.OwnerUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(a => a.Branches)
            .WithOne(b => b.Academy)
            .HasForeignKey(b => b.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(a => a.Sports)
            .WithOne(s => s.Academy)
            .HasForeignKey(s => s.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(a => a.Facilities)
            .WithOne(f => f.Academy)
            .HasForeignKey(f => f.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(a => a.Memberships)
            .WithOne(m => m.Academy)
            .HasForeignKey(m => m.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(a => a.WorkingHours)
            .WithOne(w => w.Academy)
            .HasForeignKey(w => w.AcademyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
