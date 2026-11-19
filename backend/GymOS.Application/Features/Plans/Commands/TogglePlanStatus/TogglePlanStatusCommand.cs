using MediatR;

namespace GymOS.Application.Features.Plans.Commands.TogglePlanStatus;

public record TogglePlanStatusCommand(Guid PlanId) : IRequest<bool>;