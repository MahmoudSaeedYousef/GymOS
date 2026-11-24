using GymOS.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Api.Endpoints;

public static class HealthEndpoints
{
    public static void MapHealthEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/health", async (HttpContext context, GymDbContext db) =>
        {
            var correlationId = context.Items["CorrelationId"] as string
                                ?? context.TraceIdentifier;

            try
            {
                // Lightweight connectivity probe: execute a cheap SQL scalar
                var canConnect = await db.Database.CanConnectAsync(context.RequestAborted);

                if (canConnect)
                {
                    return Results.Ok(new
                    {
                        status   = "healthy",
                        database = "up",
                        traceId  = correlationId
                    });
                }

                context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
                return Results.Json(new
                {
                    status   = "unhealthy",
                    database = "down",
                    traceId  = correlationId
                }, statusCode: StatusCodes.Status503ServiceUnavailable);
            }
            catch
            {
                context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
                return Results.Json(new
                {
                    status   = "unhealthy",
                    database = "down",
                    traceId  = correlationId
                }, statusCode: StatusCodes.Status503ServiceUnavailable);
            }
        })
        .AllowAnonymous()
        .WithName("HealthCheck")
        .WithTags("Health");
    }
}
