using System.Security.Claims;
using GymOS.Infrastructure.Data;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace GymOS.Api.Endpoints;

public record PopulateHistoryRequest(Guid? GymId);

public static class DevEndpoints
{
    public static void MapDevEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/dev")
            .WithTags("Developer Tools")
            .RequireAuthorization();

        // Populate 30-day history safely for the authorized tenant
        group.MapPost("/populate-30day-history", async (
            PopulateHistoryRequest? request,
            IGymHistorySeeder seeder,
            HttpContext httpContext,
            CancellationToken cancellationToken) =>
        {
            var tenantClaim = httpContext.User.FindFirstValue("tenant_id");
            if (!Guid.TryParse(tenantClaim, out var gymId))
            {
                return Results.Unauthorized();
            }

            var result = await seeder.Seed30DayHistoryAsync(gymId, cancellationToken: cancellationToken);

            return result.Success ? Results.Ok(result) : Results.BadRequest(result);
        });
    }
}
