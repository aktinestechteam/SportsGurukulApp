namespace SPORTSGURUKUL.Application.Coaches.Interfaces;

/// <summary>
/// Generates a cryptographically secure temporary password that satisfies the
/// application password policy. The plain-text value may only be used to
/// deliver temporary credentials to the user and must never be persisted.
/// </summary>
public interface ITemporaryPasswordGenerator
{
    string Generate();
}
