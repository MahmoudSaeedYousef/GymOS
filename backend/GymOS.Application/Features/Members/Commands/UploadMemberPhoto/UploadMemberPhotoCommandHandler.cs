using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Members.Commands.UploadMemberPhoto;

public class UploadMemberPhotoCommandHandler(
    IGymDbContext context,
    ICurrentTenantService tenantService,
    IFileStorageService fileStorageService) : IRequestHandler<UploadMemberPhotoCommand, UploadMemberPhotoResult>
{
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    };

    private const long MaxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

    public async Task<UploadMemberPhotoResult> Handle(UploadMemberPhotoCommand request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId;
        if (string.IsNullOrWhiteSpace(tenantId) || !Guid.TryParse(tenantId, out var tenantGuid))
        {
            return UploadMemberPhotoResult.BadRequest("Tenant ID is missing or invalid.");
        }

        if (request.FileStream == null || request.FileLength <= 0)
        {
            return UploadMemberPhotoResult.BadRequest("File is required and cannot be empty.");
        }

        if (request.FileLength > MaxFileSizeBytes)
        {
            return UploadMemberPhotoResult.BadRequest("File size exceeds 5 MB limit.");
        }

        var ext = Path.GetExtension(request.FileName);
        if (string.IsNullOrWhiteSpace(ext) || !AllowedExtensions.Contains(ext))
        {
            return UploadMemberPhotoResult.BadRequest("Invalid file extension. Allowed formats: .jpg, .jpeg, .png, .webp.");
        }

        var member = await context.Users
            .FirstOrDefaultAsync(u => u.Id == request.MemberId && u.TenantId == tenantGuid, cancellationToken);

        if (member == null)
        {
            return UploadMemberPhotoResult.NotFound("Member not found.");
        }

        // Delete old local photo if it exists
        if (!string.IsNullOrWhiteSpace(member.PhotoUrl))
        {
            await fileStorageService.DeleteFileAsync(member.PhotoUrl, cancellationToken);
        }

        var unixTimestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var normalizedExt = ext.ToLowerInvariant();
        var fileName = $"{member.Id}_{unixTimestamp}{normalizedExt}";
        var relativeSubPath = $"members/{tenantId}/{fileName}";

        var photoUrl = await fileStorageService.UploadFileAsync(request.FileStream, relativeSubPath, cancellationToken);

        member.PhotoUrl = photoUrl;
        await context.SaveChangesAsync(cancellationToken);

        return UploadMemberPhotoResult.Success(photoUrl);
    }
}
