using SPORTSGURUKUL.Application.Common.Interfaces;

namespace SPORTSGURUKUL.Infrastructure.Storage;

public class S3ServiceStub : IS3Service
{
    // TODO: replace with real AWSSDK.S3 implementation
    public Task<string> GeneratePresignedUploadUrlAsync(string key, string contentType, long maxFileSizeBytes)
    {
        // TODO: wire maxFileSizeBytes into presigned URL policy condition when real S3 is wired
        return Task.FromResult($"https://dummy-s3.example.com/upload/{key}");
    }

    public Task<string> GeneratePresignedDownloadUrlAsync(string key)
        => Task.FromResult($"https://dummy-s3.example.com/download/{key}");

    public Task DeleteObjectAsync(string key) => Task.CompletedTask;
}