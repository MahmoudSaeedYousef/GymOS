using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using MediatR;

namespace GymOS.Application.Features.Plans.Commands.CreatePlan;


public class CreatePlanCommandHandler(
    IGymDbContext context, 
    ICurrentTenantService tenantService,
    ICacheService cache) : IRequestHandler<CreatePlanCommand, Guid>
{
    public async Task<Guid> Handle(CreatePlanCommand request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId 
                       ?? throw new UnauthorizedAccessException("Tenant ID is missing from token.");

        var plan = new Plan
        {
            TenantId = new Guid(tenantId),
            Name = request.Name,
            Price = request.Price,
            DurationInDays = request.DurationInDays,
            MaxSessions = request.MaxSessions
        };

        context.Plans.Add(plan);
        await context.SaveChangesAsync(cancellationToken);
        await cache.RemoveAsync($"plans:{tenantId}", cancellationToken);
        return plan.Id;
    }
}