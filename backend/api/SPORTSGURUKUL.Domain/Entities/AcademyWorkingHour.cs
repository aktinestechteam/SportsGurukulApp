namespace SPORTSGURUKUL.Domain.Entities;

public class AcademyWorkingHour
{
    public Guid Id { get; set; }
    public Guid AcademyId { get; set; }
    public DayOfWeek DayOfWeek { get; set; }
    public TimeOnly? OpenTime { get; set; }
    public TimeOnly? CloseTime { get; set; }
    public bool IsClosed { get; set; }
    public DateTime CreatedAt { get; set; }

    public Academy Academy { get; set; } = null!;
}
