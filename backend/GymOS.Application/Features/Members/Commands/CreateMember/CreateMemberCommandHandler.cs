using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;
using MediatR;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Members.Commands.CreateMember;

public class CreateMemberCommandHandler(
    UserManager<ApplicationUser> userManager,
    IGymDbContext context,
    ICurrentTenantService tenantService) : IRequestHandler<CreateMemberCommand, string>
{
    public async Task<string> Handle(CreateMemberCommand request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId
            ?? throw new UnauthorizedAccessException("Tenant ID is missing.");

        Plan? plan = null;
        var startDateTime = request.OccurredAtUtc ?? request.CreatedAt ?? DateTime.UtcNow;
        var start = request.StartDate ?? DateOnly.FromDateTime(startDateTime);
        DateOnly? end = null;
        if (request.PlanId.HasValue)
        {
            plan = await context.Plans.FirstOrDefaultAsync(p => p.Id == request.PlanId.Value, cancellationToken)
                ?? throw new KeyNotFoundException("Selected plan not found.");
            end = start.AddDays(plan.DurationInDays);
        }

        var memberId = (request.Id.HasValue && request.Id.Value != Guid.Empty)
            ? request.Id.Value
            : ((request.ClientId.HasValue && request.ClientId.Value != Guid.Empty)
                ? request.ClientId.Value
                : Guid.CreateVersion7());

        var member = new ApplicationUser
        {
            Id = memberId.ToString(),
            UserName = $"{tenantId}_{request.PhoneNumber}",
            PhoneNumber = request.PhoneNumber,
            FullName = request.FullName,
            Type = UserType.Member,
            Gender = request.Gender,
            SubscriptionEndDate = end?.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc),
            TenantId = new Guid(tenantId)
        };

        var result = await userManager.CreateAsync(member, $"Gym@{request.PhoneNumber}");
        if (!result.Succeeded)
            throw new InvalidOperationException(string.Join(", ", result.Errors.Select(e => e.Description)));

        if (plan != null && end.HasValue)
        {
            var sub = new Subscription
            {
                TenantId = new Guid(tenantId),
                MemberId = member.Id,
                PlanId = plan.Id,
                StartDate = start,
                EndDate = end.Value,
                RemainingVisits = plan.Kind == PlanKind.VisitPack ? plan.VisitsIncluded : null
            };
            sub.Activate();
            context.Subscriptions.Add(sub);

            context.PaymentRecords.Add(new PaymentRecord
            {
                TenantId = tenantId,
                MemberId = member.Id,
                PlanId = plan.Id,
                Amount = request.AmountPaid ?? plan.Price,
                Method = request.Method,
                PaymentDate = startDateTime,
                IsDropIn = false,
                Notes = "اشتراك عضو جديد"
            });

            await context.SaveChangesAsync(cancellationToken);
        }

        return member.Id;
    }
}
