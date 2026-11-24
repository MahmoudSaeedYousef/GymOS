using System.Security.Claims;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Serilog.Context;

namespace GymOS.Api.Middleware;

/// <summary>
/// Enforces strict multi-tenant isolation for every authenticated HTTP request.
/// Must be registered after UseAuthentication() and before UseAuthorization().
///
/// Security contract:
///  - TenantId is read ONLY from the validated JWT claim ("tenant_id" or "TenantId").
///  - X-Tenant-Id headers are NEVER trusted.
///  - Unknown or inactive tenants are rejected with 403.
/// </summary>
public class TenantMiddleware(
    RequestDelegate next,
    ILogger<TenantMiddleware> logger)
{
    // JWT claim names accepted as the tenant identifier (checked in order).
    private static readonly string[] TenantClaimNames = ["tenant_id", "TenantId"];

    // IMemoryCache key prefix for tenant validation results.
    private const string CacheKeyPrefix = "tenant_active:";
    private static readonly TimeSpan CacheTtl = TimeSpan.FromSeconds(60);

    public async Task InvokeAsync(HttpContext context)
    {
        // Only run isolation logic for authenticated requests.
        if (context.User.Identity?.IsAuthenticated != true)
        {
            await next(context);
            return;
        }

        // --- 1. Extract TenantId strictly from JWT claims ---
        string? rawClaim = null;
        foreach (var claimName in TenantClaimNames)
        {
            rawClaim = context.User.FindFirstValue(claimName);
            if (!string.IsNullOrWhiteSpace(rawClaim)) break;
        }

        if (!Guid.TryParse(rawClaim, out var tenantId) || tenantId == Guid.Empty)
        {
            logger.LogWarning("Authenticated request missing or invalid tenant_id claim. Path={Path}", context.Request.Path);
            await WriteForbiddenAsync(context, "Tenant identifier is missing or invalid in the authentication token.");
            return;
        }

        // --- 2. Validate tenant exists and is active (IMemoryCache, 60 s TTL) ---
        var cache = context.RequestServices.GetRequiredService<IMemoryCache>();
        var cacheKey = $"{CacheKeyPrefix}{tenantId}";

        if (!cache.TryGetValue(cacheKey, out bool isActive))
        {
            // Go to DB (bypass query filters – we need the raw row)
            var db = context.RequestServices.GetRequiredService<GymOS.Infrastructure.Data.GymDbContext>();
            var tenant = await db.Tenants
                .AsNoTracking()
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(t => t.Id == tenantId, context.RequestAborted);

            isActive = tenant is { IsActive: true };
            cache.Set(cacheKey, isActive, CacheTtl);
        }

        if (!isActive)
        {
            logger.LogWarning("Authenticated request for unknown or inactive tenant {TenantId}. Path={Path}", tenantId, context.Request.Path);
            await WriteForbiddenAsync(context, "Tenant is not found or is inactive.");
            return;
        }

        // --- 3. Populate ITenantContext ---
        var tenantContext = context.RequestServices.GetRequiredService<ITenantContext>();
        tenantContext.SetTenantId(tenantId);

        // --- 4. Push TenantId into Serilog LogContext for the duration of the request ---
        using var logProp = LogContext.PushProperty("TenantId", tenantId);

        await next(context);
    }

    private static async Task WriteForbiddenAsync(HttpContext context, string message)
    {
        var traceId = context.TraceIdentifier;
        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsJsonAsync(new
        {
            type = "https://httpstatuses.io/403",
            title = "Forbidden",
            status = 403,
            message,
            traceId
        });
    }
}

public static class TenantMiddlewareExtensions
{
    /// <summary>Registers TenantMiddleware; call this after UseAuthentication() and before UseAuthorization().</summary>
    public static IApplicationBuilder UseTenantIsolation(this IApplicationBuilder app)
        => app.UseMiddleware<TenantMiddleware>();
}
