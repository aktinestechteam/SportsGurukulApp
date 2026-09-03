using Amazon.Runtime;
using Amazon.S3;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SPORTSGURUKUL.Application.Common.Interfaces;
using SPORTSGURUKUL.Application.Common.Options;

namespace SPORTSGURUKUL.Infrastructure.Storage;

public class S3Service : IS3Service
{
    private readonly IAmazonS3 _s3;
    private readonly AwsOptions _options;
    private readonly ILogger<S3Service> _logger;

    public S3Service(IAmazonS3 s3, IOptions<AwsOptions> options, ILogger<S3Service> logger)
    {
        _s3 = s3;
        _options = options.Value;
        _logger = logger;
    }

    public Task<string> GeneratePresignedUploadUrlAsync(
        string key,
        string contentType,
        long maxFileSizeBytes)
    {
        var request = new Amazon.S3.Model.GetPreSignedUrlRequest
        {
            BucketName = _options.BucketName,
            Key = key,
            Verb = Amazon.S3.HttpVerb.PUT,
            Expires = DateTime.UtcNow.AddMinutes(
                _options.UrlExpirationMinutes > 0 ? _options.UrlExpirationMinutes : 10),
            ContentType = contentType,
        };

        var url = _s3.GetPreSignedURL(request);
        return Task.FromResult(url);
    }

    public Task<string> GeneratePresignedDownloadUrlAsync(string key)
    {
        var request = new Amazon.S3.Model.GetPreSignedUrlRequest
        {
            BucketName = _options.BucketName,
            Key = key,
            Verb = Amazon.S3.HttpVerb.GET,
            Expires = DateTime.UtcNow.AddMinutes(
                _options.UrlExpirationMinutes > 0 ? _options.UrlExpirationMinutes : 10),
        };

        var url = _s3.GetPreSignedURL(request);
        return Task.FromResult(url);
    }

    public async Task DeleteObjectAsync(string key)
    {
        if (string.IsNullOrWhiteSpace(key))
        {
            return;
        }

        try
        {
            await _s3.DeleteObjectAsync(_options.BucketName, key);
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            // Object doesn't exist; nothing to clean up.
        }
        catch (Exception ex)
        {
            // Deletion failure should not break the main request; log and continue.
            _logger.LogWarning(ex, "Failed to delete S3 object '{Key}' from bucket '{Bucket}'.",
                key, _options.BucketName);
        }
    }
}
