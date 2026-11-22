using GymOS.Application.Features.Members.DTOs;
using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Members.Commands.UpdateMember;

public class UpdateMemberCommandHandler(
    IGymDbContext context,
    ICurrentTenantService tenantService) : IRequestHandler<UpdateMemberCommand, UpdateMemberResult>
{
    public async Task<UpdateMemberResult> Handle(UpdateMemberCommand request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId;
        if (string.IsNullOrWhiteSpace(tenantId) || !Guid.TryParse(tenantId, out var tenantGuid))
        {
            return UpdateMemberResult.BadRequest("Tenant ID is missing or invalid.");
        }

        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            return UpdateMemberResult.BadRequest("Full name is required.");
        }

        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            return UpdateMemberResult.BadRequest("Phone number is required.");
        }

        var cleanFullName = request.FullName.Trim();
        var cleanPhoneNumber = request.PhoneNumber.Trim();

        var member = await context.Users
            .FirstOrDefaultAsync(u => u.Id == request.Id && u.TenantId == tenantGuid, cancellationToken);

        if (member == null)
        {
            return UpdateMemberResult.NotFound("Member not found.");
        }

        // Phone number uniqueness check within the same TenantId, excluding current member
        var phoneExists = await context.Users
            .AnyAsync(u => u.Id != member.Id && u.TenantId == tenantGuid && u.PhoneNumber == cleanPhoneNumber, cancellationToken);

        if (phoneExists)
        {
            return UpdateMemberResult.BadRequest("Phone number is already in use by another member.");
        }

        member.FullName = cleanFullName;
        member.PhoneNumber = cleanPhoneNumber;
        member.UserName = $"{tenantId}_{cleanPhoneNumber}";

        await context.SaveChangesAsync(cancellationToken);

        var now = DateTime.UtcNow;
        var latestSub = await context.Subscriptions
            .Where(s => s.MemberId == member.Id)
            .OrderByDescending(s => s.EndDate)
            .Select(s => new
            {
                PlanName = s.Plan.Name,
                s.EndDate
            })
            .FirstOrDefaultAsync(cancellationToken);

        var subscriptionStatus = (latestSub == null || member.SubscriptionEndDate == null || member.SubscriptionEndDate < now)
            ? "Expired"
            : "Active";

        var memberDto = new MemberDto(
            member.Id,
            member.FullName,
            member.PhoneNumber ?? string.Empty,
            latestSub?.PlanName,
            latestSub?.EndDate,
            subscriptionStatus,
            member.PhotoUrl);

        return UpdateMemberResult.Success(memberDto);
    }
}
