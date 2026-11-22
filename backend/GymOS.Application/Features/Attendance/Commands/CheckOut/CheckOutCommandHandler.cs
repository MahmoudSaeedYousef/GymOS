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
        var targetId = request.RecordId != Guid.Empty
            ? request.RecordId
            : (request.AttendanceId ?? Guid.Empty);

        if (targetId == Guid.Empty)
            return new CheckOutResult(false, "معرف سجل الحضور غير صالح.");

        var record = context.AttendanceRecords.Local.FirstOrDefault(a => a.Id == targetId)
            ?? await context.AttendanceRecords.FirstOrDefaultAsync(a => a.Id == targetId, cancellationToken);

        if (record == null)
            return new CheckOutResult(false, "سجل الحضور غير موجود.");

        if (record.CheckOutTime != null)
            return new CheckOutResult(true, "تم تسجيل خروج المشترك بالفعل.");

        record.CheckOutTime = request.OccurredAtUtc ?? request.CheckOutTime ?? DateTime.UtcNow;
        await context.SaveChangesAsync(cancellationToken);

        return new CheckOutResult(true, "تم تسجيل الخروج بنجاح.");
    }
}
