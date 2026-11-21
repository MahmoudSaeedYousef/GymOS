namespace GymOS.Application.Features.Attendance.DTOs;

public record AttendanceHistoryDto(
    Guid RecordId,
    string MemberId,
    string FullName,
    string? PhoneNumber,
    DateTime CheckInTime,
    DateTime? CheckOutTime
);
