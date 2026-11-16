using GymOS.Application.Interfaces;

namespace GymOS.Infrastructure.Services;

public class LocalFileStorageService : IFileStorageService
{
    // هنا بنكتب تفاصيل الحفظ الفعلي على الـ Hard Disk بتاع الـ VPS
    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default)
    {
        var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", fileName);
        
        using var stream = new FileStream(filePath, FileMode.Create);
        await fileStream.CopyToAsync(stream, cancellationToken);
        
        return $"/uploads/{fileName}"; // Relative URL
    }

    public Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default)
    {
        // لوجيك مسح الملف من الهارد
        return Task.CompletedTask;
    }
}