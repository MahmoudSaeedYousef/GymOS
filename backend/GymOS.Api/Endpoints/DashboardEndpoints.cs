using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using GymOS.Application.Features.Dashboard.Queries.GetStats;

namespace GymOS.Api.Endpoints;

public static class DashboardEndpoints
{
    public static void MapDashboardEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/dashboard").RequireAuthorization();

        group.MapGet("/stats", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetDashboardStatsQuery());
            return Results.Ok(result);
        });
    }
}