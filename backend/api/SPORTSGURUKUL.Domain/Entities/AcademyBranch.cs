namespace SPORTSGURUKUL.Domain.Entities;

public class AcademyBranch
{
    public Guid Id { get; set; }
    public Guid AcademyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string? PostalCode { get; set; }
    public string? ContactEmail { get; set; }
    public string? ContactPhone { get; set; }
    public bool IsMain { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public Academy Academy { get; set; } = null!;
    public ICollection<AcademyCoach> CoachAssociations { get; set; } = [];
}
