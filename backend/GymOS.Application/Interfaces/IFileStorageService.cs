namespace GymOS.Application.Interfaces;

public interface IFileStorageService
{
    // العقد واضح: خد الملف ورجعلي المسار أو الـ URL بتاعه
    Task<string> UploadFileAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default);
    Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default);
}