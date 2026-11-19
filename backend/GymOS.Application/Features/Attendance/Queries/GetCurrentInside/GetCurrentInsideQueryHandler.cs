using GymOS.Application.Features.Attendance.DTOs;
using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Application.Interfaces;

namespace GymOS.Application.Features.Attendance.Queries.GetCurrentInside;

public class GetCurrentInsideQueryHandler(IGymDbContext context)
    : IRequestHandler<GetCurrentInsideQuery, List<CurrentInsideMemberDto>>
{
    public async Task<List<CurrentInsideMemberDto>> Handle(
        GetCurrentInsideQuery request,
        CancellationToken cancellationToken)
    {
        var sessionMinutes = await context.Tenants
            .Select(t => (int?)t.DefaultSessionDurationMinutes)
            .FirstOrDefaultAsync(cancellationToken) ?? 120;

        var cutoffTime = DateTime.UtcNow.AddMinutes(-sessionMinutes);

        return await context.AttendanceRecords
            .Where(a => a.CheckOutTime == null && a.CheckInTime >= cutoffTime)
            .OrderByDescending(a => a.CheckInTime)
            .Select(a => new CurrentInsideMemberDto(
                a.Id,
                a.MemberId,
                a.Member.FullName,
                a.Member.PhoneNumber ?? string.Empty,
                a.CheckInTime
            ))
            .ToListAsync(cancellationToken);
    }
}