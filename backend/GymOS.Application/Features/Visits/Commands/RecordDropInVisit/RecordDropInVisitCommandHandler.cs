using GymOS.Application.Features.Visits.DTOs;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Visits.Commands.RecordDropInVisit;

public class RecordDropInVisitCommandHandler(
    IGymDbContext context,
    ICurrentTenantService currentTenantService)
    : IRequestHandler<RecordDropInVisitCommand, DropInVisitResult>
{
    public async Task<DropInVisitResult> Handle(
        RecordDropInVisitCommand request,
        CancellationToken cancellationToken)
    {
        var tenantIdString = currentTenantService.TenantId;
        if (!Guid.TryParse(tenantIdString, out var tenantId))
            return new DropInVisitResult(false, "تعذر تحديد الجيم الحالي.");

        // 1. فحص الـ Idempotency (لو العملية اتبعتت قبل كده بنفس OperationId نرجع نفس النتيجة فوراً)
        var existingPayment = await context.PaymentRecords
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.OperationId == request.OperationId, cancellationToken);

        if (existingPayment != null)
        {
            return new DropInVisitResult(
                Succeeded: true,
                Message: "تم تسجيل الحصة مسبقاً.",
                PaymentId: existingPayment.Id,
                MemberId: existingPayment.MemberId,
                AmountPaid: existingPayment.Amount
            );
        }

        // 2. جلب أو إنشاء باقة الحصة المفردة الافتراضية لو الجيم لسه ما أنشأش واحدة
        Plan? dropInPlan = null;
        if (request.PlanId.HasValue)
        {
            dropInPlan = await context.Plans
                .FirstOrDefaultAsync(p => p.Id == request.PlanId.Value && p.Kind == PlanKind.VisitPack, cancellationToken);
        }
        else
        {
            dropInPlan = await context.Plans
                .OrderBy(p => p.Price)
                .FirstOrDefaultAsync(p => p.Kind == PlanKind.VisitPack && p.VisitsIncluded == 1 && p.IsActive, cancellationToken);
        }

        var finalAmount = request.CustomAmount ?? dropInPlan?.Price ?? 0;
        if (finalAmount <= 0)
            return new DropInVisitResult(false, "يرجى تحديد سعر صالح للحصة أو إنشاء باقة حصة مفردة.");

        var now = request.OccurredAtUtc ?? request.CreatedAt ?? DateTime.UtcNow;
        var today = DateOnly.FromDateTime(now);

        var paymentId = (request.Id.HasValue && request.Id.Value != Guid.Empty)
            ? request.Id.Value
            : ((request.ClientId.HasValue && request.ClientId.Value != Guid.Empty)
                ? request.ClientId.Value
                : Guid.CreateVersion7());

        var attendanceId = (request.AttendanceId.HasValue && request.AttendanceId.Value != Guid.Empty)
            ? request.AttendanceId.Value
            : (request.ClientId.HasValue && request.Id.HasValue && request.ClientId.Value != request.Id.Value
                ? request.ClientId.Value
                : Guid.CreateVersion7());

        await using var transaction = await context.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            // 3. لو الجيم معندوش باقة VisitPack بـ 1 زيارة، ننشئ واحدة افتراضية تلقائياً عشان Subscription.PlanId مطلوب
            if (dropInPlan == null)
            {
                dropInPlan = new Plan
                {
                    Id = Guid.CreateVersion7(),
                    TenantId = tenantId,
                    Name = "حصة مفردة",
                    Price = finalAmount,
                    DurationInDays = 1,
                    Kind = PlanKind.VisitPack,
                    VisitsIncluded = 1,
                    IsActive = true
                };
                context.Plans.Add(dropInPlan);
            }

            // 4. جلب العضو برقم الهاتف (لو متسجل قبل كده) أو إنشاء زائر جديد (Guest)
            ApplicationUser? member = null;
            var cleanPhone = string.IsNullOrWhiteSpace(request.GuestPhone) ? null : request.GuestPhone.Trim();
            var cleanName = string.IsNullOrWhiteSpace(request.GuestName) ? "زائر حصة مفردة" : request.GuestName.Trim();

            if (cleanPhone != null)
            {
                member = await context.Users
                    .FirstOrDefaultAsync(u => u.PhoneNumber == cleanPhone, cancellationToken);
            }

            if (member == null)
            {
                var uniqueSuffix = Guid.NewGuid().ToString("N");
                member = new ApplicationUser
                {
                    Id = Guid.CreateVersion7().ToString(),
                    TenantId = tenantId,
                    Type = UserType.Member,
                    FullName = cleanName,
                    PhoneNumber = cleanPhone,
                    UserName = $"guest_{uniqueSuffix}",
                    NormalizedUserName = $"GUEST_{uniqueSuffix}".ToUpperInvariant(),
                    IsGuest = true
                };
                context.Users.Add(member);
            }

            // 5. إنشاء استحقاق (Subscription) كـ VisitPack وتفعيله ثم استهلاك الزيارة فوراً
            var subscription = new Subscription
            {
                Id = Guid.CreateVersion7(),
                TenantId = tenantId,
                MemberId = member.Id,
                PlanId = dropInPlan.Id,
                StartDate = today,
                EndDate = today,
                RemainingVisits = 1
            };
            subscription.Activate();      // Pending -> Active
            subscription.ConsumeVisit();  // RemainingVisits: 1 -> 0, Status -> Expired
            context.Subscriptions.Add(subscription);

            // 6. تسجيل الحضور الفوري (يسمّع في "المتواجدين الآن" و"حضور اليوم")
            var attendance = new AttendanceRecord
            {
                Id = attendanceId,
                TenantId = tenantIdString!,
                MemberId = member.Id,
                CheckInTime = now,
                Notes = string.IsNullOrWhiteSpace(request.Notes) ? "حصة مفردة" : request.Notes
            };
            context.AttendanceRecords.Add(attendance);

            // 7. تسجيل الدفعة في الـ Ledger
            var payment = new PaymentRecord
            {
                Id = paymentId,
                TenantId = tenantIdString!,
                MemberId = member.Id,
                PlanId = dropInPlan.Id,
                Amount = finalAmount,
                Method = request.Method,
                PaymentDate = now,
                OperationId = request.OperationId,
                IsDropIn = true,
                Notes = string.IsNullOrWhiteSpace(request.Notes) ? "حصة مفردة" : request.Notes
            };
            context.PaymentRecords.Add(payment);

            await context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            return new DropInVisitResult(
                Succeeded: true,
                Message: "تم تسجيل الحصة المفردة بنجاح.",
                PaymentId: payment.Id,
                AttendanceId: attendance.Id,
                MemberId: member.Id,
                AmountPaid: finalAmount
            );
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }
}
