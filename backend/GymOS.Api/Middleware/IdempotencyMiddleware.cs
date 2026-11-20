using System.Security.Claims;
using System.Text;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace GymOS.Api.Middleware;

public class IdempotencyMiddleware(RequestDelegate next)
{
    private const string IdempotencyHeader = "X-Idempotency-Key";
    private const string IdempotentReplayHeader = "X-Idempotent-Replay";

    public async Task InvokeAsync(HttpContext context)
    {
        // Only inspect mutating HTTP methods (POST, PUT, PATCH)
        if (!HttpMethods.IsPost(context.Request.Method) &&
            !HttpMethods.IsPut(context.Request.Method) &&
            !HttpMethods.IsPatch(context.Request.Method))
        {
            await next(context);
            return;
        }

        // If X-Idempotency-Key header is missing or empty, pass through normally
        if (!context.Request.Headers.TryGetValue(IdempotencyHeader, out var headerValue) ||
            string.IsNullOrWhiteSpace(headerValue))
        {
            await next(context);
            return;
        }

        var idempotencyKey = headerValue.ToString().Trim();
        if (string.IsNullOrEmpty(idempotencyKey))
        {
            await next(context);
            return;
        }

        if (idempotencyKey.Length > 100)
        {
            idempotencyKey = idempotencyKey[..100];
        }

        // Resolve current GymId from authenticated tenant context / claims
        var gymId = ResolveGymId(context);
        if (!gymId.HasValue || gymId.Value == Guid.Empty)
        {
            // If GymId cannot be resolved (e.g. unauthenticated request), pass through normally
            await next(context);
            return;
        }

        var dbContext = context.RequestServices.GetRequiredService<IGymDbContext>();
        var now = DateTime.UtcNow;

        // Check IdempotencyRecords for (GymId, IdempotencyKey) where ExpiresAtUtc > DateTime.UtcNow
        var existingRecord = await dbContext.IdempotencyRecords
            .IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.GymId == gymId.Value && r.IdempotencyKey == idempotencyKey && r.ExpiresAtUtc > now, context.RequestAborted);

        if (existingRecord != null)
        {
            // Short-circuit immediately
            context.Response.StatusCode = existingRecord.StatusCode;
            context.Response.ContentType = "application/json";
            context.Response.Headers[IdempotentReplayHeader] = "true";
            await context.Response.WriteAsync(existingRecord.ResponseBody, Encoding.UTF8, context.RequestAborted);
            return;
        }

        // If not found: capture response stream / status code
        var originalBodyStream = context.Response.Body;
        await using var memoryStream = new MemoryStream();
        context.Response.Body = memoryStream;

        try
        {
            await next(context);

            memoryStream.Position = 0;
            var responseBodyText = await new StreamReader(memoryStream, Encoding.UTF8, leaveOpen: true).ReadToEndAsync(context.RequestAborted);
            memoryStream.Position = 0;

            // Only persist if the endpoint succeeds (200..299). Do NOT cache 5xx server errors so transient failures can be retried.
            if (context.Response.StatusCode >= 200 && context.Response.StatusCode <= 299)
            {
                var record = new IdempotencyRecord
                {
                    Id = Guid.CreateVersion7(),
                    GymId = gymId.Value,
                    IdempotencyKey = idempotencyKey,
                    RequestPath = context.Request.Path.Value?.Length > 256
                        ? context.Request.Path.Value[..256]
                        : (context.Request.Path.Value ?? string.Empty),
                    StatusCode = context.Response.StatusCode,
                    ResponseBody = responseBodyText,
                    CreatedAtUtc = DateTime.UtcNow,
                    ExpiresAtUtc = DateTime.UtcNow.AddHours(48)
                };

                try
                {
                    dbContext.IdempotencyRecords.Add(record);
                    await dbContext.SaveChangesAsync(context.RequestAborted);
                }
                catch (DbUpdateException)
                {
                    // In case of a race condition with concurrent identical requests, ignore unique constraint conflict
                }
            }

            context.Response.ContentLength = memoryStream.Length;
            await memoryStream.CopyToAsync(originalBodyStream, context.RequestAborted);
        }
        finally
        {
            context.Response.Body = originalBodyStream;
        }
    }

    private static Guid? ResolveGymId(HttpContext context)
    {
        var tenantClaim = context.User.FindFirstValue("tenant_id")
            ?? context.User.FindFirstValue("gym_id")
            ?? context.User.FindFirstValue("GymId")
            ?? context.User.FindFirstValue("TenantId");

        if (Guid.TryParse(tenantClaim, out var parsedClaimId) && parsedClaimId != Guid.Empty)
        {
            return parsedClaimId;
        }

        var tenantService = context.RequestServices.GetService<ICurrentTenantService>();
        if (tenantService != null && Guid.TryParse(tenantService.TenantId, out var parsedServiceId) && parsedServiceId != Guid.Empty)
        {
            return parsedServiceId;
        }

        if (context.Request.Headers.TryGetValue("X-Gym-Id", out var gymHeader) &&
            Guid.TryParse(gymHeader, out var parsedHeaderId) && parsedHeaderId != Guid.Empty)
        {
            return parsedHeaderId;
        }

        return null;
    }
}

public static class IdempotencyMiddlewareExtensions
{
    public static IApplicationBuilder UseIdempotency(this IApplicationBuilder app)
    {
        return app.UseMiddleware<IdempotencyMiddleware>();
    }
}
