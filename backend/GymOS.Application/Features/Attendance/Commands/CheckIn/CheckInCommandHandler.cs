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

            var openSessions = await context.AttendanceRecords
                .Where(a => a.MemberId == member.Id && a.CheckOutTime == null)
                .ToListAsync(cancellationToken);

            foreach (var session in openSessions)
            {
                session.CheckOutTime = checkInTime;
            }

            var recordId = (request.ClientId.HasValue && request.ClientId.Value != Guid.Empty)
                ? request.ClientId.Value
                : (!string.IsNullOrWhiteSpace(request.MemberId) && Guid.TryParse(request.Id, out var parsedGuid) && parsedGuid != Guid.Empty
                    ? parsedGuid
                    : Guid.CreateVersion7());

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
