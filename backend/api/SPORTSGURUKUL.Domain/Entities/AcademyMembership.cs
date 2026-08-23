namespace SPORTSGURUKUL.Domain.Entities;

public class AcademyMembership
{
    public Guid Id { get; set; }
    public Guid AcademyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int DurationDays { get; set; }
    public decimal Price { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public Academy Academy { get; set; } = null!;
}
