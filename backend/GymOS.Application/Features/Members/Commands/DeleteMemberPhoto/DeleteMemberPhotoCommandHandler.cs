using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace GymOS.Application.Features.Members.Commands.DeleteMemberPhoto;

public class DeleteMemberPhotoCommandHandler(
    IGymDbContext context,
    ICurrentTenantService tenantService,
    IFileStorageService fileStorageService,
    ILogger<DeleteMemberPhotoCommandHandler>? logger = null) : IRequestHandler<DeleteMemberPhotoCommand, DeleteMemberPhotoResult>
{
    public async Task<DeleteMemberPhotoResult> Handle(DeleteMemberPhotoCommand request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId;
        if (string.IsNullOrWhiteSpace(tenantId) || !Guid.TryParse(tenantId, out var tenantGuid))
        {
            return DeleteMemberPhotoResult.BadRequest("Tenant ID is missing or invalid.");
        }

        var member = await context.Users
            .FirstOrDefaultAsync(u => u.Id == request.MemberId && u.TenantId == tenantGuid, cancellationToken);

        if (member == null)
        {
            return DeleteMemberPhotoResult.NotFound("Member not found.");
        }

        var oldPhotoUrl = member.PhotoUrl;

        member.PhotoUrl = null;
        await context.SaveChangesAsync(cancellationToken);

        if (!string.IsNullOrWhiteSpace(oldPhotoUrl))
        {
            try
            {
                await fileStorageService.DeleteFileAsync(oldPhotoUrl, cancellationToken);
            }
            catch (Exception ex)
            {
                logger?.LogWarning(ex, "Failed to delete photo file '{OldPhotoUrl}' for member {MemberId}", oldPhotoUrl, member.Id);
            }
        }

        return DeleteMemberPhotoResult.Success();
    }
}
