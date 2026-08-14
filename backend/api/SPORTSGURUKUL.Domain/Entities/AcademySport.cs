namespace SPORTSGURUKUL.Domain.Entities;

public class AcademySport
{
    public Guid Id { get; set; }
    public Guid AcademyId { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public Academy Academy { get; set; } = null!;
    public ICollection<CoachSport> CoachSports { get; set; } = [];
    public ICollection<AthleteSport> AthleteSports { get; set; } = [];
}
