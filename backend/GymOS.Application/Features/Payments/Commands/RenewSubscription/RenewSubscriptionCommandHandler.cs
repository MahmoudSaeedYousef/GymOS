using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;

namespace GymOS.Application.Features.Payments.Commands.RenewSubscription;

public class RenewSubscriptionCommandHandler(IGymDbContext context)
    : IRequestHandler<RenewSubscriptionCommand, RenewSubscriptionResult>
{
    public async Task<RenewSubscriptionResult> Handle(RenewSubscriptionCommand request, CancellationToken cancellationToken)
    {
        // 1. جلب المشترك
        var member = await context.Users
            .FirstOrDefaultAsync(u => u.Id == request.MemberId, cancellationToken);

        if (member == null)
            return new RenewSubscriptionResult(false, "المشترك غير موجود.", null);

        // 2. جلب الباقة
        var plan = await context.Plans
            .FirstOrDefaultAsync(p => p.Id == request.PlanId, cancellationToken);

        if (plan == null)
            return new RenewSubscriptionResult(false, "الباقة المختارة غير موجودة.", null);

        // 3. حساب تواريخ البداية والنهاية
        var paymentDate = request.OccurredAtUtc ?? request.CreatedAt ?? DateTime.UtcNow;
        DateOnly startDate = DateOnly.FromDateTime(paymentDate);
        if (member.SubscriptionEndDate.HasValue)
        {
            var currentEnd = DateOnly.FromDateTime(member.SubscriptionEndDate.Value);
            if (currentEnd > startDate)
                startDate = currentEnd; // هيبدأ من تاريخ نهاية باقته الحالية
        }
        var newEndDate = startDate.AddDays(plan.DurationInDays);

        // 4. تحديث الـ User (Denormalization للسرعة وقت تسجيل الحضور)
        member.SubscriptionEndDate = newEndDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        member.IsGuest = false;

        // 5. توثيق الاشتراك في الدفتر التاريخي (جدول Subscriptions)
        var subId = (request.SubscriptionId.HasValue && request.SubscriptionId.Value != Guid.Empty)
            ? request.SubscriptionId.Value
            : ((request.Id.HasValue && request.Id.Value != Guid.Empty)
                ? request.Id.Value
                : ((request.ClientId.HasValue && request.ClientId.Value != Guid.Empty)
                    ? request.ClientId.Value
                    : Guid.CreateVersion7()));

        var subscription = new Subscription
        {
            Id = subId,
            MemberId = member.Id,
            TenantId = member.TenantId,
            PlanId = plan.Id,
            StartDate = startDate,
            EndDate = newEndDate,
        };
        subscription.Activate();
        context.Subscriptions.Add(subscription);

        // 6. توثيق المدفوعات
        var payId = (request.PaymentId.HasValue && request.PaymentId.Value != Guid.Empty)
            ? request.PaymentId.Value
            : Guid.CreateVersion7();

        var paymentRecord = new PaymentRecord
        {
            Id = payId,
            MemberId = member.Id,
            TenantId = member.TenantId.ToString(),
            PlanId = plan.Id,
            Amount = request.AmountPaid > 0 ? request.AmountPaid : plan.Price,
            Method = request.PaymentMethod,
            PaymentDate = paymentDate,
            Notes = request.Notes
        };
        context.PaymentRecords.Add(paymentRecord);

        // 7. حفظ كل الـ Transactions في خبطة واحدة
        await context.SaveChangesAsync(cancellationToken);

        return new RenewSubscriptionResult(true, "تم تجديد الاشتراك بنجاح.", newEndDate);
    }
}
