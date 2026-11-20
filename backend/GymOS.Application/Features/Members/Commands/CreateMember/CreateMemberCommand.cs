using GymOS.Domain.Enums;
using MediatR;

namespace GymOS.Application.Features.Members.Commands.CreateMember;

public record CreateMemberCommand(
    string FullName,
    string PhoneNumber,
    Guid? PlanId,
    DateOnly? StartDate,
    PaymentMethod Method = PaymentMethod.Cash,
    decimal? AmountPaid = null,
    Guid? Id = null,
    Guid? ClientId = null,
    DateTime? OccurredAtUtc = null,
    DateTime? CreatedAt = null) : IRequest<string>;
