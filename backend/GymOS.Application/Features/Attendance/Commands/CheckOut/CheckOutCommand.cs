using GymOS.Application.Features.Attendance.DTOs;
using MediatR;

namespace GymOS.Application.Features.Attendance.Commands.CheckOut;

public record CheckOutCommand(
    Guid RecordId,
    DateTime? OccurredAtUtc = null,
    DateTime? CheckOutTime = null) : IRequest<CheckOutResult>;
