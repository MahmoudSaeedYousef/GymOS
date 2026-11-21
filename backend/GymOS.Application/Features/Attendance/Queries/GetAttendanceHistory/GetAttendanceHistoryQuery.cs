using GymOS.Application.Features.Attendance.DTOs;
using MediatR;

namespace GymOS.Application.Features.Attendance.Queries.GetAttendanceHistory;

public record GetAttendanceHistoryQuery(
    DateTime? StartDate = null,
    DateTime? EndDate = null
) : IRequest<List<AttendanceHistoryDto>>;
