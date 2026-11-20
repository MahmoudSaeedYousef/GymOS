using GymOS.Application.Features.Visits.DTOs;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Visits.Commands.VoidDropIn;



public class VoidDropInCommandHandler(
    IGymDbContext context,
    ICurrentTenantService currentTenantService)
    : IRequestHandler<VoidDropInCommand, VoidDropInResult>
{
    public async Task<VoidDropInResult> Handle(
        VoidDropInCommand request,
        CancellationToken cancellationToken)
    {
        var originalPayment = await context.PaymentRecords
            .FirstOrDefaultAsync(p => p.Id == request.PaymentId && p.IsDropIn, cancellationToken);

        if (originalPayment == null)
            return new VoidDropInResult(false, "سجل الحصة غير موجود.");

        if (originalPayment.Amount <= 0)
            return new VoidDropInResult(false, "لا يمكن إلغاء قيد عكسي.");

        var alreadyReversed = await context.PaymentRecords
            .AnyAsync(p => p.ReversedPaymentId == originalPayment.Id, cancellationToken);

        if (alreadyReversed)
            return new VoidDropInResult(false, "تم إلغاء هذه الحصة مسبقاً.");

        var now = DateTime.UtcNow;

        // 1. إنشاء قيد عكسي بالسالب في الـ Ledger
        var reversalPayment = new PaymentRecord
        {
            Id = Guid.CreateVersion7(),
            TenantId = currentTenantService.TenantId!,
            MemberId = originalPayment.MemberId,
            PlanId = originalPayment.PlanId,
            Amount = -originalPayment.Amount,
            Method = originalPayment.Method,
            PaymentDate = now,
            IsDropIn = true,
            ReversedPaymentId = originalPayment.Id,
            Notes = $"إلغاء حصة مفردة: {request.Reason}"
        };
        context.PaymentRecords.Add(reversalPayment);

        // 2. إنهاء جلسة الحضور المفتوحة لهذا الزائر إن وجدت
        var openAttendance = await context.AttendanceRecords
            .Where(a => a.MemberId == originalPayment.MemberId && a.CheckOutTime == null)
            .OrderByDescending(a => a.CheckInTime)
            .FirstOrDefaultAsync(cancellationToken);

        if (openAttendance != null)
        {
            openAttendance.CheckOutTime = now;
            openAttendance.Notes = $"{openAttendance.Notes} (تم الإلغاء)";
        }

        await context.SaveChangesAsync(cancellationToken);

        return new VoidDropInResult(true, "تم إلغاء الحصة وتسجيل قيد عكسي بنجاح.");
    }
}