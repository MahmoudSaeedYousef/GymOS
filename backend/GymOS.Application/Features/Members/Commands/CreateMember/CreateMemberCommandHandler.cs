using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
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

        var member = new ApplicationUser
        {
            UserName = $"{tenantId}_{request.PhoneNumber}", // لضمان عدم تعارض UserName بين الجيمات المختلفة
            PhoneNumber = request.PhoneNumber,
            FullName = request.FullName,
            SubscriptionEndDate = DateTime.UtcNow.Date.AddDays(30),
            TenantId = new Guid(tenantId)
        };

        // إنشاء العضو بباسورد افتراضي مؤقت (أو بدون باسورد لو الدخول بـ OTP مستقبلاً)
        var result = await userManager.CreateAsync(member, $"Gym@{request.PhoneNumber}");
        if (!result.Succeeded)
            throw new InvalidOperationException(string.Join(", ", result.Errors.Select(e => e.Description)));

        // لو اختار باقة أثناء التسجيل، نفعّل الاشتراك فوراً
        if (request.PlanId.HasValue)
        {
            var plan = await context.Plans.FirstOrDefaultAsync(p => p.Id == request.PlanId.Value, cancellationToken)
                ?? throw new KeyNotFoundException("Selected plan not found.");

            var start = request.StartDate ?? DateOnly.FromDateTime(DateTime.UtcNow);
            var sub = new Subscription
            {
                TenantId = new Guid(tenantId),
                MemberId = member.Id,
                PlanId = plan.Id,
                StartDate = start,
                EndDate = start.AddDays(plan.DurationInDays)
            };
            sub.Activate();
            context.Subscriptions.Add(sub);
            await context.SaveChangesAsync(cancellationToken);
        }

        return member.Id;
    }
}