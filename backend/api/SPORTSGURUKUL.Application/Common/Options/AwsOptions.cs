namespace SPORTSGURUKUL.Application.Common.Options;

public class AwsOptions
{
    public string AccessKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public string BucketName { get; set; } = string.Empty;
    public string Region { get; set; } = "us-east-1";

    /// <summary>Lifetime of presigned URLs in minutes (default 10).</summary>
    public int UrlExpirationMinutes { get; set; } = 10;
}
