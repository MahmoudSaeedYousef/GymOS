using GymOS.Domain.Enums;
using MediatR;

namespace GymOS.Application.Features.Payments.Commands.RenewSubscription;

// الداتا اللي جاية من الموبايل
public record RenewSubscriptionCommand(
    string MemberId, 
    Guid PlanId, 
    PaymentMethod PaymentMethod, 
    decimal AmountPaid, 
    string? Notes = null,
    Guid? Id = null,
    Guid? ClientId = null,
    DateTime? OccurredAtUtc = null,
    DateTime? CreatedAt = null,
    Guid? SubscriptionId = null,
    Guid? PaymentId = null
) : IRequest<RenewSubscriptionResult>;

public record RenewSubscriptionResult(bool IsSuccess, string Message, DateOnly? NewEndDate);
