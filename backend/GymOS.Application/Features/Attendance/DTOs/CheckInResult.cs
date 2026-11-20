namespace GymOS.Application.Features.Attendance.DTOs;

public record CheckInResult(bool IsSuccess, string Message, Guid? AttendanceId = null);
