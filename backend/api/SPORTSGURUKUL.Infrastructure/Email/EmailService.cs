using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Authentication.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;

namespace SPORTSGURUKUL.Infrastructure.Email;

public class EmailService : IEmailService
{
    private readonly EmailOptions _options;
    private readonly IHostEnvironment _environment;
    private readonly ILogger<EmailService> _logger;

    public EmailService(
        IOptions<EmailOptions> options,
        IHostEnvironment environment,
        ILogger<EmailService> logger)
    {
        _options = options.Value;
        _environment = environment;
        _logger = logger;
    }

    public Task SendPasswordResetAsync(string toEmail, string firstName, string resetLink, CancellationToken cancellationToken = default)
    {
        var body = BuildHtml(
            $"Hi {firstName},",
            "We received a request to reset your password. Use the link below to choose a new password. This link expires in one hour.",
            "Reset Password",
            resetLink,
            "If you did not request this, you can safely ignore this email.");

        return SendAsync(toEmail, "SPORTSGURUKUL - Reset your password", body, cancellationToken);
    }

    public Task SendEmailVerificationAsync(string toEmail, string firstName, string verificationLink, CancellationToken cancellationToken = default)
    {
        var body = BuildHtml(
            $"Hi {firstName},",
            "Please verify your email address to complete your SPORTS GURUKUL account setup.",
            "Verify Email",
            verificationLink,
            "If you did not create an account, you can safely ignore this email.");

        return SendAsync(toEmail, "SPORTSGURUKUL - Verify your email", body, cancellationToken);
    }

    private async Task SendAsync(string toEmail, string subject, string body, CancellationToken cancellationToken)
    {
        var provider = _options.Provider?.ToLowerInvariant();

        switch (provider)
        {
            case "file":
                await WriteToFileAsync(toEmail, subject, body, cancellationToken);
                break;
            case "smtp":
                await SendViaSmtpAsync(toEmail, subject, body, cancellationToken);
                break;
            default:
                _logger.LogWarning(
                    "Email provider '{Provider}' is not configured. Email to {ToEmail} was not sent.",
                    provider,
                    toEmail);
                break;
        }
    }

    private Task WriteToFileAsync(string toEmail, string subject, string body, CancellationToken cancellationToken)
    {
        var directory = Path.Combine(_environment.ContentRootPath, "App_Data", "emails");
        Directory.CreateDirectory(directory);

        var fileName = $"{DateTime.UtcNow:yyyyMMdd_HHmmss_fff}_{Guid.NewGuid():N}.html";
        var filePath = Path.Combine(directory, fileName);

        var content = $"""
            <html>
            <body>
            <h2>To: {toEmail}</h2>
            <h3>Subject: {subject}</h3>
            <hr/>
            {body}
            </body>
            </html>
            """;

        return File.WriteAllTextAsync(filePath, content, cancellationToken);
    }

    private async Task SendViaSmtpAsync(string toEmail, string subject, string body, CancellationToken cancellationToken)
    {
        using var smtp = new SmtpClient(_options.Host, _options.Port)
        {
            EnableSsl = true,
            Credentials = new NetworkCredential(_options.Username, _options.Password)
        };

        var message = new MailMessage(
            new MailAddress(_options.FromEmail, _options.FromName),
            new MailAddress(toEmail))
        {
            Subject = subject,
            IsBodyHtml = true,
            Body = body
        };

        await smtp.SendMailAsync(message, cancellationToken);
    }

    private string BuildHtml(string greeting, string instruction, string buttonLabel, string link, string footer)
    {
        var safeButtonLabel = HtmlEncode(buttonLabel);
        var safeLink = HtmlEncode(link);

        return $"""
            <div style="font-family:Arial,Helvetica,sans-serif;max-width:600px;margin:0 auto;">
              <h2 style="color:#1a237e;">SPORTSGURUKUL</h2>
              <p>{HtmlEncode(greeting)}</p>
              <p>{HtmlEncode(instruction)}</p>
              <p style="text-align:center;">
                <a href="{safeLink}"
                   style="background-color:#1a237e;color:#ffffff;padding:12px 24px;text-decoration:none;border-radius:6px;display:inline-block;">
                  {safeButtonLabel}
                </a>
              </p>
              <p>Or open this link:</p>
              <p><a href="{safeLink}">{safeLink}</a></p>
              <p style="color:#757575;font-size:12px;">{HtmlEncode(footer)}</p>
            </div>
            """;
    }

    private static string HtmlEncode(string value) => WebUtility.HtmlEncode(value);
}
