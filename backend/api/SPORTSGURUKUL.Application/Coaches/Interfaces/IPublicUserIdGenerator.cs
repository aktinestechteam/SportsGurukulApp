namespace SPORTSGURUKUL.Application.Coaches.Interfaces;

/// <summary>
/// Generates a unique human-readable user identifier (for example
/// "SG-COACH-000123"). Uniqueness is enforced by the caller against the
/// unique database constraint on the user's public identifier.
/// </summary>
public interface IPublicUserIdGenerator
{
    Task<string> GenerateAsync(string prefix, CancellationToken cancellationToken = default);
}
