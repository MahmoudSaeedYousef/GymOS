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
            .FirstOrDefaultAsync(u => u.Id == request.Id && u.TenantId == tenantGuid && !u.IsGuest, cancellationToken);

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

        var subscriptionStatus = (latestSub == null || member.SubscriptionEndDate == null || member.SubscriptionEndDate < now)
            ? "Expired"
            : "Active";

        return new MemberDto(
            member.Id,
            member.FullName,
            member.PhoneNumber ?? string.Empty,
            latestSub?.PlanName,
            latestSub?.EndDate,
            subscriptionStatus,
            member.PhotoUrl,
            member.Gender);
    }
}
