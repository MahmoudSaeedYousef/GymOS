using GymOS.Application.Features.Visits.DTOs;
using GymOS.Domain.Enums;
using MediatR;
namespace GymOS.Application.Features.Visits.Commands.RecordDropInVisit;

public record RecordDropInVisitCommand(
    Guid OperationId,
    Guid? PlanId,
    decimal? CustomAmount,
    string PaymentMethod,
    string? GuestName,
    string? GuestPhone,
    string? Notes,
 PaymentMethod Method

) : IRequest<DropInVisitResult>;