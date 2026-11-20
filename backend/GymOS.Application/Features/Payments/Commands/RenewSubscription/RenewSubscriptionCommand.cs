using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;

namespace GymOS.Application.Features.Payments.Commands.RenewSubscription;

// الداتا اللي جاية من الموبايل
public record RenewSubscriptionCommand(
    string MemberId, 
    Guid PlanId, 
    PaymentMethod PaymentMethod, 
    decimal AmountPaid, 
    string? Notes = null
) : IRequest<RenewSubscriptionResult>;

public record RenewSubscriptionResult(bool IsSuccess, string Message, DateOnly? NewEndDate);

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
        DateOnly startDate = DateOnly.FromDateTime(DateTime.UtcNow);
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
        var subscription = new Subscription
        {
            MemberId = member.Id,
            TenantId = member.TenantId,
            PlanId = plan.Id,
            StartDate = startDate,
            EndDate = newEndDate,
            // Status = "Active" // فعلها لو عندك Enum للحالة
        };
        subscription.Activate();
        context.Subscriptions.Add(subscription);

        // 6. توثيق المدفوعات
        var paymentRecord = new PaymentRecord
        {
            MemberId = member.Id,
            TenantId = member.TenantId.ToString(),
            PlanId = plan.Id,
            Amount = request.AmountPaid > 0 ? request.AmountPaid : plan.Price,
            Method = request.PaymentMethod,
            PaymentDate = DateTime.UtcNow,
            Notes = request.Notes
            // يفضل لو تضيف SubscriptionId جوا الـ PaymentRecord وتربطهم ببعض
        };
        context.PaymentRecords.Add(paymentRecord);

        // 7. حفظ كل الـ Transactions في خبطة واحدة
        await context.SaveChangesAsync(cancellationToken);

        return new RenewSubscriptionResult(true, "تم تجديد الاشتراك بنجاح.", newEndDate);
    }
}