using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SPORTSGURUKUL.Domain.Entities;

namespace SPORTSGURUKUL.Infrastructure.Persistence.Configurations;

public class AcademyWorkingHourConfiguration : IEntityTypeConfiguration<AcademyWorkingHour>
{
    public void Configure(EntityTypeBuilder<AcademyWorkingHour> builder)
    {
        builder.ToTable("AcademyWorkingHours");

        builder.HasKey(w => w.Id);

        builder.Property(w => w.DayOfWeek)
            .HasConversion<int>()
            .IsRequired();

        builder.Property(w => w.OpenTime)
            .HasColumnType("time");

        builder.Property(w => w.CloseTime)
            .HasColumnType("time");

        builder.Property(w => w.IsClosed)
            .IsRequired();

        builder.Property(w => w.CreatedAt)
            .IsRequired();

        builder.HasIndex(w => w.AcademyId)
            .HasDatabaseName("IX_AcademyWorkingHours_AcademyId");
    }
}
