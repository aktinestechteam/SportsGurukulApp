using System.Security.Cryptography;
using SPORTSGURUKUL.Application.Coaches.Interfaces;

namespace SPORTSGURUKUL.Infrastructure.Security;

public class PublicUserIdGenerator : IPublicUserIdGenerator
{
    public Task<string> GenerateAsync(string prefix, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(prefix))
        {
            prefix = "SG-COACH";
        }

        var suffix = RandomNumberGenerator.GetInt32(1_000_000).ToString("D6");
        return Task.FromResult($"{prefix}-{suffix}");
    }
}
