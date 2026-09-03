namespace SPORTSGURUKUL.Application.Videos.DTOs;

public sealed class NotificationResponse
{
    public string Type { get; set; } = string.Empty;
    public string VideoId { get; set; } = string.Empty;
    public string VideoTitle { get; set; } = string.Empty;
    public string ActorName { get; set; } = string.Empty;
    public string? AthleteId { get; set; }
    public DateTime CreatedAt { get; set; }
}
