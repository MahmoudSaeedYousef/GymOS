using GymOS.Application.Features.Attendance.DTOs;

namespace GymOS.Application.Features.Attendance.Commands.CheckOut;

using MediatR;
public record CheckOutCommand(Guid RecordId) : IRequest<CheckOutResult>;