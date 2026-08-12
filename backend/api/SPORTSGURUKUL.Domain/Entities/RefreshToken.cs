namespace SPORTSGURUKUL.Domain.Entities;

public class RefreshToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public Guid? ReplacedByTokenId { get; set; }
    public string? CreatedByIp { get; set; }
    public string? RevokedByIp { get; set; }

    public User User { get; set; } = null!;

    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public string RawToken { get; set; } = string.Empty;

    public bool IsActive => RevokedAt is null && !IsExpired;
    public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
}
