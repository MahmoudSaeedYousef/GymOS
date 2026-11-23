using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace GymOS.Application.Features.Members.Commands.UploadMemberPhoto;

public class UploadMemberPhotoCommandHandler(
    IGymDbContext context,
    ICurrentTenantService tenantService,
    IFileStorageService fileStorageService,
    ILogger<UploadMemberPhotoCommandHandler>? logger = null) : IRequestHandler<UploadMemberPhotoCommand, UploadMemberPhotoResult>
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

        // 1. Capture the member's previous PhotoUrl before overwriting it
        var oldPhotoUrl = member.PhotoUrl;

        var unixTimestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var normalizedExt = ext.ToLowerInvariant();
        var fileName = $"{member.Id}_{unixTimestamp}{normalizedExt}";
        var relativeSubPath = $"members/{tenantId}/{fileName}";

        // 2. Save the new photo and update the database first
        var photoUrl = await fileStorageService.UploadFileAsync(request.FileStream, relativeSubPath, cancellationToken);

        member.PhotoUrl = photoUrl;
        await context.SaveChangesAsync(cancellationToken);

        // 3. After new photo is saved and DB update succeeds, if old PhotoUrl was non-empty and differs from new one:
        if (!string.IsNullOrWhiteSpace(oldPhotoUrl) && !string.Equals(oldPhotoUrl, photoUrl, StringComparison.OrdinalIgnoreCase))
        {
            try
            {
                await fileStorageService.DeleteFileAsync(oldPhotoUrl, cancellationToken);
            }
            catch (Exception ex)
            {
                logger?.LogWarning(ex, "Failed to delete old photo file '{OldPhotoUrl}' for member {MemberId}", oldPhotoUrl, member.Id);
            }
        }

        return UploadMemberPhotoResult.Success(photoUrl);
    }
}
