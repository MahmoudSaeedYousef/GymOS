namespace GymOS.Application.Features.Attendance.DTOs;

public record CurrentInsideMemberDto(
    Guid RecordId,
    string MemberId,
    string FullName,
    string PhoneNumber,
    DateTime CheckInTime,
    string? PhotoUrl = null
);