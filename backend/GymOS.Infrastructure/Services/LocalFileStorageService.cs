using GymOS.Application.Interfaces;

namespace GymOS.Infrastructure.Services;

public class LocalFileStorageService : IFileStorageService
{
    private readonly string _webRootPath;
    private readonly string _baseUploadsPath;

    public LocalFileStorageService()
    {
        _webRootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        _baseUploadsPath = Path.Combine(_webRootPath, "uploads");
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
            var fullPath = Path.Combine(_webRootPath, cleanPath);
            if (File.Exists(fullPath))
            {
                File.Delete(fullPath);
            }
        }
        catch
        {
            // Safely ignore deletion errors
        }

        return Task.CompletedTask;
    }
}
