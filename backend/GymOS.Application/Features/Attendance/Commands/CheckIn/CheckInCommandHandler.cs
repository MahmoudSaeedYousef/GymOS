using GymOS.Application.Features.Attendance.DTOs;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Attendance.Commands.CheckIn;

public class CheckInCommandHandler(IGymDbContext context) : IRequestHandler<CheckInCommand, CheckInResult>
{
    public async Task<CheckInResult> Handle(CheckInCommand request, CancellationToken cancellationToken)
    {
        try
        {
            var memberIdentifier = !string.IsNullOrWhiteSpace(request.MemberId)
                ? request.MemberId
                : request.Id;

            if (string.IsNullOrWhiteSpace(memberIdentifier))
                return new CheckInResult(false, "معرف المشترك مطلوب.");

            var member = await context.Users
                .FirstOrDefaultAsync(u => u.Id == memberIdentifier, cancellationToken);

            if (member == null)
                return new CheckInResult(false, "المشترك غير موجود.");

            if (member.SubscriptionEndDate < DateTime.UtcNow)
                return new CheckInResult(false, "لا يمكن تسجيل الحضور، اشتراك العميل منتهي.");

            var checkInTime = request.OccurredAtUtc ?? request.CheckInTime ?? DateTime.UtcNow;

            var isDistinctClientId = request.ClientId.HasValue
                && request.ClientId.Value != Guid.Empty
                && (!Guid.TryParse(member.Id, out var memberGuid) || request.ClientId.Value != memberGuid);

            var recordId = isDistinctClientId
                ? request.ClientId!.Value
                : Guid.CreateVersion7();

            if (recordId == Guid.Empty)
            {
                recordId = Guid.CreateVersion7();
            }

            // 1. فحص ما إذا كان السجل موجوداً محلياً بالذاكرة أو بقاعدة البيانات فقط عند وجود ClientId فريد (Idempotent retry من Offline Sync)
            if (isDistinctClientId)
            {
                var trackedRecord = context.AttendanceRecords.Local.FirstOrDefault(a => a.Id == recordId);
                if (trackedRecord != null)
                {
                    if (!string.IsNullOrWhiteSpace(request.Notes) && trackedRecord.Notes != request.Notes)
                    {
                        trackedRecord.Notes = request.Notes;
                        await context.SaveChangesAsync(cancellationToken);
                    }
                    return new CheckInResult(true, "تم تسجيل الحضور بنجاح.", trackedRecord.Id);
                }

                var existingRecord = await context.AttendanceRecords
                    .FirstOrDefaultAsync(a => a.Id == recordId, cancellationToken);

                if (existingRecord != null)
                {
                    if (!string.IsNullOrWhiteSpace(request.Notes) && existingRecord.Notes != request.Notes)
                    {
                        existingRecord.Notes = request.Notes;
                        await context.SaveChangesAsync(cancellationToken);
                    }
                    return new CheckInResult(true, "تم تسجيل الحضور بنجاح.", existingRecord.Id);
                }
            }

            // 2. إغلاق الجلسات المفتوحة السابقة لهذا العضو (مع استبعاد recordId)
            var openSessions = await context.AttendanceRecords
                .Where(a => a.MemberId == member.Id && a.CheckOutTime == null && a.Id != recordId)
                .ToListAsync(cancellationToken);

            foreach (var session in openSessions)
            {
                session.CheckOutTime = checkInTime;
            }

            var record = new AttendanceRecord
            {
                Id = recordId,
                MemberId = member.Id,
                TenantId = member.TenantId.ToString(),
                CheckInTime = checkInTime,
                Notes = request.Notes
            };

            context.AttendanceRecords.Add(record);
            await context.SaveChangesAsync(cancellationToken);

            return new CheckInResult(true, "تم تسجيل الحضور بنجاح.", record.Id);
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            throw;
        }
    }
}
