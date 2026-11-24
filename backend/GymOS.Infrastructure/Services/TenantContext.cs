using GymOS.Application.Interfaces;

namespace GymOS.Infrastructure.Services;

/// <summary>
/// Scoped tenant context.  Registered as Scoped so each HTTP request / DI scope gets its own instance.
/// An AsyncLocal provides per-async-flow override for background/non-HTTP scopes that call BeginScope.
/// </summary>
public sealed class TenantContext : ITenantContext
{
    // Per-async-flow override (used by background services / hosted services).
    private static readonly AsyncLocal<Guid?> _asyncLocalTenantId = new();

    // Per-instance value – set by TenantMiddleware for HTTP request scopes.
    private Guid? _instanceTenantId;

    /// <inheritdoc />
    public Guid? TenantId => _instanceTenantId ?? _asyncLocalTenantId.Value;

    /// <inheritdoc />
    public bool IsResolved => TenantId.HasValue && TenantId.Value != Guid.Empty;

    /// <inheritdoc />
    public void SetTenantId(Guid tenantId)
    {
        _instanceTenantId = tenantId;
    }

    /// <inheritdoc />
    public IDisposable BeginScope(Guid tenantId)
    {
        var previous = _asyncLocalTenantId.Value;
        _asyncLocalTenantId.Value = tenantId;
        _instanceTenantId = tenantId;
        return new ScopeHandle(() =>
        {
            _asyncLocalTenantId.Value = previous;
            _instanceTenantId = null;
        });
    }

    private sealed class ScopeHandle(Action onDispose) : IDisposable
    {
        private bool _disposed;

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            onDispose();
        }
    }
}
