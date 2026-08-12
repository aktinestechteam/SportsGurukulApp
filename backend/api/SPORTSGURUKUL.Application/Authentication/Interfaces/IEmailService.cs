namespace SPORTSGURUKUL.Application.Authentication.Interfaces;

public interface IEmailService
{
    Task SendPasswordResetAsync(string toEmail, string firstName, string resetLink, CancellationToken cancellationToken = default);
    Task SendEmailVerificationAsync(string toEmail, string firstName, string verificationLink, CancellationToken cancellationToken = default);
}
