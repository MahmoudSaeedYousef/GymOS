using GymOS.Application.Features.Members.DTOs;
using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Members.Queries.GetMembersSummary;

public class GetMembersSummaryQueryHandler(IGymDbContext context)
    : IRequestHandler<GetMembersSummaryQuery, MembersSummaryDto>
{
    public async Task<MembersSummaryDto> Handle(
        GetMembersSummaryQuery request,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var today = now.Date;
        var fiveDaysFromToday = today.AddDays(5);

        // All non-guest members for current tenant (scoped via EF Core global query filter)
        var nonGuestMembers = context.Users
            .AsNoTracking()
            .Where(u => !u.IsGuest);

        var total = await nonGuestMembers.CountAsync(cancellationToken);

        // Matching GetDashboardStatsQueryHandler: Active members count
        var active = await nonGuestMembers
            .CountAsync(u => u.SubscriptionEndDate >= now, cancellationToken);

        // Matching GetDashboardStatsQueryHandler: Expired non-guest members count
        var expired = await nonGuestMembers
            .CountAsync(u => u.SubscriptionEndDate < now || u.SubscriptionEndDate == null, cancellationToken);

        // Same exact condition as Task 1: active subscriptions ending within 5 days [today, today + 5 days]
        var expiringSoon = await nonGuestMembers
            .CountAsync(u => u.SubscriptionEndDate >= today && u.SubscriptionEndDate <= fiveDaysFromToday, cancellationToken);

        // Grouped count of members per assigned plan (planName), ordered by count descending
        // Project each non-guest member to their latest subscription's plan
        var memberPlans = await nonGuestMembers
            .Select(u => context.Subscriptions
                .Where(s => s.MemberId == u.Id)
                .OrderByDescending(s => s.EndDate)
                .Select(s => new
                {
                    PlanId = (Guid?)s.PlanId,
                    PlanName = s.Plan != null ? s.Plan.Name : "بدون باقة"
                })
                .FirstOrDefault())
            .ToListAsync(cancellationToken);

        var plans = memberPlans
            .GroupBy(p => new
            {
                PlanId = p?.PlanId,
                PlanName = p?.PlanName ?? "بدون باقة"
            })
            .Select(g => new MemberPlanSummaryDto(
                PlanId: g.Key.PlanId,
                PlanName: g.Key.PlanName,
                Count: g.Count()
            ))
            .OrderByDescending(p => p.Count)
            .ThenBy(p => p.PlanName)
            .ToList();

        return new MembersSummaryDto(
            Total: total,
            Active: active,
            Expired: expired,
            ExpiringSoon: expiringSoon,
            Plans: plans
        );
    }
}
