using GymOS.Application.Features.Attendance.DTOs;
using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Attendance.Queries.GetAttendanceHistory;

public class GetAttendanceHistoryQueryHandler(IGymDbContext context)
    : IRequestHandler<GetAttendanceHistoryQuery, List<AttendanceHistoryDto>>
{
    public async Task<List<AttendanceHistoryDto>> Handle(
        GetAttendanceHistoryQuery request,
        CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var end = request.EndDate ?? now;
        var start = request.StartDate ?? now.AddDays(-30);

        return await context.AttendanceRecords
            .AsNoTracking()
            .Where(a => a.CheckInTime >= start && a.CheckInTime <= end)
            .OrderByDescending(a => a.CheckInTime)
            .Select(a => new AttendanceHistoryDto(
                a.Id,
                a.MemberId,
                a.Member.FullName,
                a.Member.PhoneNumber,
                a.CheckInTime,
                a.CheckOutTime
            ))
            .ToListAsync(cancellationToken);
    }
}
