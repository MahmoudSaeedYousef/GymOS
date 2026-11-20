using GymOS.Application.Features.Attendance.DTOs;
using MediatR;

namespace GymOS.Application.Features.Attendance.Commands.CheckIn;

public record CheckInCommand(
    string? Id = null,
    string? Notes = null,
    Guid? ClientId = null,
    string? MemberId = null,
    DateTime? OccurredAtUtc = null,
    DateTime? CheckInTime = null) : IRequest<CheckInResult>;
