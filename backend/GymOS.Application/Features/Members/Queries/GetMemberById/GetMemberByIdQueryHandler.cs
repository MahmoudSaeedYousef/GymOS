using GymOS.Application.Features.Members.DTOs;
using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Members.Queries.GetMemberById;

public class GetMemberByIdQueryHandler(
    IGymDbContext context,
    ICurrentTenantService tenantService) : IRequestHandler<GetMemberByIdQuery, MemberDto?>
{
    public async Task<MemberDto?> Handle(GetMemberByIdQuery request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId;
        if (string.IsNullOrWhiteSpace(tenantId) || !Guid.TryParse(tenantId, out var tenantGuid))
        {
            return null;
        }

        var member = await context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == request.Id && u.TenantId == tenantGuid, cancellationToken);

        if (member == null)
        {
            return null;
        }

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

        var isSingleSession = member.IsGuest;
        var subscriptionStatus = isSingleSession
            ? "Expired"
            : ((latestSub == null || member.SubscriptionEndDate == null || member.SubscriptionEndDate < now)
                ? "Expired"
                : "Active");

        var planName = isSingleSession
            ? (latestSub?.PlanName ?? "حصة منفردة")
            : latestSub?.PlanName;

        var displayName = isSingleSession && (string.IsNullOrWhiteSpace(member.FullName) || member.FullName == "زائر حصة مفردة")
            ? "حصة منفردة"
            : member.FullName;

        return new MemberDto(
            member.Id,
            displayName,
            member.PhoneNumber ?? string.Empty,
            planName,
            latestSub?.EndDate,
            subscriptionStatus,
            member.PhotoUrl,
            member.Gender,
            IsGuest: member.IsGuest,
            IsSingleSession: isSingleSession);
    }
}
