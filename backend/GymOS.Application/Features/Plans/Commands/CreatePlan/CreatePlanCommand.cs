using MediatR;

namespace GymOS.Application.Features.Plans.Commands.CreatePlan;

public record CreatePlanCommand(string Name, decimal Price, int DurationInDays, int? MaxSessions) : IRequest<Guid>;
