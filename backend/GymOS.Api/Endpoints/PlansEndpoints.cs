using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Application.Interfaces;
using GymOS.Application.Features.Plans.Commands.UpsertPlan;
using GymOS.Application.Features.Plans.Commands.TogglePlanStatus;

namespace GymOS.Api.Endpoints;

public static class PlansEndpoints
{
    public static void MapPlansEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/plans").RequireAuthorization();

        // جلب كل الباقات (مع باراميتر اختياري activeOnly عشان شيت التجديد يجيب النشط بس)
        group.MapGet("/", async (bool? activeOnly, IGymDbContext context) =>
        {
            var query = context.Plans.AsQueryable();
            if (activeOnly == true)
                query = query.Where(p => p.IsActive);

            var plans = await query
                .OrderBy(p => p.DurationInDays)
                .ToListAsync();

            return Results.Ok(plans);
        });

        group.MapPost("/", async (UpsertPlanCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess ? Results.Ok(result) : Results.BadRequest(result);
        });

        group.MapPatch("/{id:guid}/toggle", async (Guid id, IMediator mediator) =>
        {
            var updated = await mediator.Send(new TogglePlanStatusCommand(id));
            return updated ? Results.Ok() : Results.NotFound();
        });
    }
}