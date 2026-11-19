using GymOS.Application.Features.Attendance.DTOs;
using MediatR;

namespace GymOS.Application.Features.Attendance.Commands.CheckIn;

public record CheckInCommand(string Id, string? Notes = null) : IRequest<CheckInResult>;