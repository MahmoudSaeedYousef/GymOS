using GymOS.Application.Interfaces;

namespace GymOS.Tests.Helpers;

public class TestTenantService(string? tenantId = null) : ICurrentTenantService
{
    public string? TenantId { get; set; } = tenantId;
}
