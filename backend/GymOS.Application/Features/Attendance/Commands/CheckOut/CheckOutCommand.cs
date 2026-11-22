using GymOS.Application.Features.Attendance.DTOs;
using MediatR;

namespace GymOS.Application.Features.Attendance.Commands.CheckOut;

public record CheckOutCommand(
    Guid RecordId = default,
    DateTime? OccurredAtUtc = null,
    DateTime? CheckOutTime = null,
    Guid? AttendanceId = null) : IRequest<CheckOutResult>;
