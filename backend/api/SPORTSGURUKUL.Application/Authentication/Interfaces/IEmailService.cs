namespace SPORTSGURUKUL.Application.Authentication.Interfaces;

public interface IEmailService
{
    Task SendPasswordResetAsync(string toEmail, string firstName, string resetLink, CancellationToken cancellationToken = default);
    Task SendEmailVerificationAsync(string toEmail, string firstName, string verificationLink, CancellationToken cancellationToken = default);

    /// <summary>
    /// Sends the temporary login credentials to a newly created academy coach.
    /// Returns true only when email delivery was successfully initiated.
    /// </summary>
    Task<bool> SendCoachCredentialsAsync(
        string toEmail,
        string firstName,
        string academyName,
        string publicUserId,
        string temporaryPassword,
        string loginUrl,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Sends the temporary login credentials to a newly created academy athlete.
    /// Returns true only when email delivery was successfully initiated.
    /// </summary>
    Task<bool> SendAthleteCredentialsAsync(
        string toEmail,
        string firstName,
        string academyName,
        string publicUserId,
        string temporaryPassword,
        string loginUrl,
        CancellationToken cancellationToken = default);
}
