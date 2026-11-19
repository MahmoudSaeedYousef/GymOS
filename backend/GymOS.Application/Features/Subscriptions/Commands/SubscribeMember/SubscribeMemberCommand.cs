using MediatR;

namespace GymOS.Application.Features.Subscriptions.Commands.SubscribeMember;

public record SubscribeMemberCommand(string MemberId, Guid PlanId, DateOnly StartDate) : IRequest<Guid>;
