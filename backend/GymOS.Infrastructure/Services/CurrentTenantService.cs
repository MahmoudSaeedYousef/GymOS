using System.Security.Claims;
using GymOS.Application.Interfaces;
using Microsoft.AspNetCore.Http;

namespace GymOS.Infrastructure.Services;

/// <summary>
/// Implements ICurrentTenantService by reading from the ITenantContext (set by TenantMiddleware
/// for HTTP requests, or via BeginScope for background jobs) with a fallback to JWT claims.
/// String-based for backward compatibility with existing query filters.
/// </summary>
public class CurrentTenantService(
    IHttpContextAccessor httpContextAccessor,
    ITenantContext tenantContext) : ICurrentTenantService
{
    public string? TenantId
    {
        get
        {
            // Primary: use the middleware-resolved ITenantContext (safe, JWT-validated)
            if (tenantContext.IsResolved)
                return tenantContext.TenantId!.Value.ToString();

            // Fallback: read directly from the JWT claim (unauthenticated or pre-middleware paths)
            var tenantClaim = httpContextAccessor.HttpContext?.User?.FindFirstValue("tenant_id")
                           ?? httpContextAccessor.HttpContext?.User?.FindFirstValue("TenantId");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId.ToString() : null;
        }
    }
}