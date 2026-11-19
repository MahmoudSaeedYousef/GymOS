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
            var member = await context.Users
                .FirstOrDefaultAsync(u => u.Id == request.Id, cancellationToken);

            if (member == null)
                return new CheckInResult(false, "المشترك غير موجود.");

            if (member.SubscriptionEndDate < DateTime.UtcNow)
                return new CheckInResult(false, "لا يمكن تسجيل الحضور، اشتراك العميل منتهي.");
            var openSessions = await context.AttendanceRecords
                .Where(a => a.MemberId == member.Id && a.CheckOutTime == null)
                .ToListAsync(cancellationToken);

            foreach (var session in openSessions)
            {
                session.CheckOutTime = DateTime.UtcNow;
            }
            var record = new AttendanceRecord
            {
                MemberId = member.Id,
                TenantId = member.TenantId.ToString(),
                CheckInTime = DateTime.UtcNow,
                Notes = request.Notes
            };

            context.AttendanceRecords.Add(record);
            await context.SaveChangesAsync(cancellationToken);

        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            throw;
        }
        
        return new CheckInResult(true, "تم تسجيل الحضور بنجاح.");
    }
}