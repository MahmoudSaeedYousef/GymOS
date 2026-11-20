namespace GymOS.Application.Features.Visits.DTOs;

public record DropInVisitResult(
    bool Succeeded,
    string Message,
    Guid? PaymentId = null,
    Guid? AttendanceId = null,
    string? MemberId = null,
    decimal AmountPaid = 0
);