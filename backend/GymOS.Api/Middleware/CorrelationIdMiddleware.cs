using Serilog.Context;

namespace GymOS.Api.Middleware;

/// <summary>
/// Reads X-Correlation-Id from incoming request headers (or generates an 8-char hex string),
/// echoes it on the response, and pushes it into the Serilog LogContext alongside TenantId.
/// </summary>
public class CorrelationIdMiddleware(RequestDelegate next)
{
    private const string CorrelationIdHeader = "X-Correlation-Id";

    public async Task InvokeAsync(HttpContext context)
    {
        // 1. Read or generate Correlation ID
        var correlationId = context.Request.Headers.TryGetValue(CorrelationIdHeader, out var headerVal)
                            && !string.IsNullOrWhiteSpace(headerVal)
            ? headerVal.ToString().Trim()
            : GenerateCorrelationId();

        // 2. Store on HttpContext.Items so other middleware / handlers can read it
        context.Items["CorrelationId"] = correlationId;

        // 3. Echo on response header — set early and again via OnStarting so it
        //    survives even if another middleware has already initiated the response.
        context.Response.Headers[CorrelationIdHeader] = correlationId;
        context.Response.OnStarting(() =>
        {
            // Idempotent re-set so the header is always present in the final response
            context.Response.Headers[CorrelationIdHeader] = correlationId;
            return Task.CompletedTask;
        });

        // 4. Resolve TenantId for log enrichment (best-effort)
        var tenantId = ResolveTenantId(context);

        // 5. Push both into Serilog LogContext for the duration of this request
        using (LogContext.PushProperty("CorrelationId", correlationId))
        using (LogContext.PushProperty("TenantId", tenantId ?? "unknown"))
        {
            await next(context);
        }
    }

    // --- helpers -----------------------------------------------------------

    private static string GenerateCorrelationId()
        => Convert.ToHexString(Guid.NewGuid().ToByteArray())[..8].ToLowerInvariant();

    private static string? ResolveTenantId(HttpContext context)
    {
        // Try JWT claim first
        var claim = context.User?.FindFirst("tenant_id")
                    ?? context.User?.FindFirst("gym_id")
                    ?? context.User?.FindFirst("TenantId");
        if (claim != null) return claim.Value;

        // Fall back to the tenant service
        var tenantService = context.RequestServices.GetService<GymOS.Application.Interfaces.ICurrentTenantService>();
        return tenantService?.TenantId;
    }
}

public static class CorrelationIdMiddlewareExtensions
{
    public static IApplicationBuilder UseCorrelationId(this IApplicationBuilder app)
        => app.UseMiddleware<CorrelationIdMiddleware>();
}
