namespace GymOS.Application.Interfaces;

/// <summary>
/// Scoped tenant context that works for both HTTP requests (populated by TenantMiddleware)
/// and background/non-HTTP scopes (populated via BeginScope).
/// </summary>
public interface ITenantContext
{
    /// <summary>Resolved tenant identifier for the current scope; null when not yet resolved.</summary>
    Guid? TenantId { get; }

    /// <summary>True when TenantId has been set for the current scope.</summary>
    bool IsResolved { get; }

    /// <summary>
    /// Sets the TenantId for the current async scope (background jobs, hosted services).
    /// Dispose the returned handle to clear the override.
    /// </summary>
    IDisposable BeginScope(Guid tenantId);

    /// <summary>Sets TenantId for the current scope without returning a disposable handle.</summary>
    void SetTenantId(Guid tenantId);
}
