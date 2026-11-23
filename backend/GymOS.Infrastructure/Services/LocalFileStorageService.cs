using GymOS.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace GymOS.Infrastructure.Services;

public class LocalFileStorageService : IFileStorageService
{
    private readonly string _webRootPath;
    private readonly string _baseUploadsPath;
    private readonly ILogger<LocalFileStorageService>? _logger;

    public LocalFileStorageService(ILogger<LocalFileStorageService>? logger = null)
    {
        _webRootPath = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"));
        _baseUploadsPath = Path.GetFullPath(Path.Combine(_webRootPath, "uploads"));
        _logger = logger;
    }

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default)
    {
        var cleanPath = fileName.TrimStart('/', '\\').Replace('/', Path.DirectorySeparatorChar);
        var fullPath = Path.Combine(_baseUploadsPath, cleanPath);
        var dir = Path.GetDirectoryName(fullPath);
        if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
        {
            Directory.CreateDirectory(dir);
        }

        await using var stream = new FileStream(fullPath, FileMode.Create);
        await fileStream.CopyToAsync(stream, cancellationToken);

        return $"/uploads/{cleanPath.Replace('\\', '/')}";
    }

    public Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(fileUrl))
                return Task.CompletedTask;

            var cleanPath = fileUrl.TrimStart('/', '\\').Replace('/', Path.DirectorySeparatorChar);
            var fullPath = Path.GetFullPath(Path.Combine(_webRootPath, cleanPath));

            // Guard against path traversal—only delete files inside the configured uploads directory
            var uploadsPrefix = _baseUploadsPath.EndsWith(Path.DirectorySeparatorChar)
                ? _baseUploadsPath
                : _baseUploadsPath + Path.DirectorySeparatorChar;

            if (!fullPath.StartsWith(uploadsPrefix, StringComparison.OrdinalIgnoreCase))
            {
                _logger?.LogWarning("Attempted path traversal deletion outside uploads directory: {FileUrl}", fileUrl);
                return Task.CompletedTask;
            }

            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
            }
        }
        catch (Exception ex)
        {
            _logger?.LogWarning(ex, "Failed to delete old file: {FileUrl}", fileUrl);
        }

        return Task.CompletedTask;
    }
}
