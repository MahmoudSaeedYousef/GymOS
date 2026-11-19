using System.Security.Claims;
using GymOS.Application.Interfaces;
using Microsoft.AspNetCore.Http;

namespace GymOS.Infrastructure.Services;

public class CurrentTenantService(IHttpContextAccessor httpContextAccessor) : ICurrentTenantService
{
    public String? TenantId
    {
        get
        {
            var tenantClaim = httpContextAccessor.HttpContext?.User?.FindFirstValue("tenant_id");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId.ToString() : null;
        }
    }
}