namespace SPORTSGURUKUL.Application.Common.Interfaces;

public interface IS3Service
{
    Task<string> GeneratePresignedUploadUrlAsync(string key, string contentType, long maxFileSizeBytes);
    Task<string> GeneratePresignedDownloadUrlAsync(string key);
    Task DeleteObjectAsync(string key);
}