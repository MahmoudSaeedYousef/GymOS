using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Subscriptions.Commands.SubscribeMember;


public class SubscribeMemberCommandHandler(IGymDbContext context, ICurrentTenantService tenantService)
    : IRequestHandler<SubscribeMemberCommand, Guid>
{
    public async Task<Guid> Handle(SubscribeMemberCommand request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId 
                       ?? throw new UnauthorizedAccessException("Tenant ID is missing.");

        var plan = await context.Plans.FirstOrDefaultAsync(p => p.Id == request.PlanId, cancellationToken)
                   ?? throw new KeyNotFoundException("Plan not found.");

        var subscription = new Subscription
        {
            TenantId = new Guid(tenantId),
            MemberId = request.MemberId,
            PlanId = plan.Id,
            StartDate = request.StartDate,
            EndDate = request.StartDate.AddDays(plan.DurationInDays)
        };

        // تفعيل الاشتراك عبر الـ State Machine Guard
        subscription.Activate();

        var member = await context.Users
            .FirstOrDefaultAsync(u => u.Id == request.MemberId, cancellationToken)
            ?? throw new KeyNotFoundException("Member not found.");

        member.SubscriptionEndDate = subscription.EndDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        member.IsGuest = false;

        context.Subscriptions.Add(subscription);
        await context.SaveChangesAsync(cancellationToken);

        return subscription.Id;
    }
}