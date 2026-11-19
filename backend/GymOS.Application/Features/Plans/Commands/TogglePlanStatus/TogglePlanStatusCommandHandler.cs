using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Plans.Commands.TogglePlanStatus;

public class TogglePlanStatusCommandHandler(IGymDbContext context)
    : IRequestHandler<TogglePlanStatusCommand, bool>
{
    public async Task<bool> Handle(TogglePlanStatusCommand request, CancellationToken cancellationToken)
    {
        var plan = await context.Plans.FirstOrDefaultAsync(p => p.Id == request.PlanId, cancellationToken);
        if (plan == null) return false;

        plan.IsActive = !plan.IsActive;
        await context.SaveChangesAsync(cancellationToken);
        return true;
    }
}