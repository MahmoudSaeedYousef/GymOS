using GymOS.Domain.Enums;
using MediatR;

namespace GymOS.Application.Features.Members.Commands.CreateMember;

public record CreateMemberCommand(
    string FullName,
    string PhoneNumber,
    Guid? PlanId = null,
    DateOnly? StartDate = null,
    PaymentMethod Method = PaymentMethod.Cash,
    decimal? AmountPaid = null,
    Guid? Id = null,
    Guid? ClientId = null,
    DateTime? OccurredAtUtc = null,
    DateTime? CreatedAt = null,
    Gender Gender = Gender.Unspecified) : IRequest<string>;
