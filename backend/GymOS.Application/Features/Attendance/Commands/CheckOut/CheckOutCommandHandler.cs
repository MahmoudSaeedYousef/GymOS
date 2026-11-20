using GymOS.Application.Features.Attendance.DTOs;
using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Application.Interfaces;

namespace GymOS.Application.Features.Attendance.Commands.CheckOut;

public class CheckOutCommandHandler(IGymDbContext context)
    : IRequestHandler<CheckOutCommand, CheckOutResult>
{
    public async Task<CheckOutResult> Handle(CheckOutCommand request, CancellationToken cancellationToken)
    {
        var record = await context.AttendanceRecords
            .FirstOrDefaultAsync(a => a.Id == request.RecordId, cancellationToken);

        if (record == null)
            return new CheckOutResult(false, "سجل الحضور غير موجود.");

        if (record.CheckOutTime != null)
            return new CheckOutResult(false, "تم تسجيل خروج المشترك بالفعل.");

        record.CheckOutTime = request.OccurredAtUtc ?? request.CheckOutTime ?? DateTime.UtcNow;
        await context.SaveChangesAsync(cancellationToken);

        return new CheckOutResult(true, "تم تسجيل الخروج بنجاح.");
    }
}
