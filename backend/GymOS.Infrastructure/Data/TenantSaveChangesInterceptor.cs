using GymOS.Application.Interfaces;
using GymOS.Domain.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace GymOS.Infrastructure.Data;

/// <summary>
/// EF Core write guard that enforces multi-tenant isolation on every SaveChanges call.
///
/// Rules:
///  Added   – auto-populate TenantId when empty/default; throw if explicitly set to a mismatched value.
///  Modified/Deleted – verify entity.TenantId == resolved TenantId; throw on any mismatch.
///
/// Entities must implement ITenantEntity (via BaseEntity) to participate in the guard.
/// Non-tenant entities (e.g. GymTenant itself, IdentityRole, IdempotencyRecord) are skipped.
/// </summary>
public sealed class TenantSaveChangesInterceptor(ITenantContext tenantContext) : SaveChangesInterceptor
{
    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData,
        InterceptionResult<int> result)
    {
        Guard(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        Guard(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private void Guard(DbContext? context)
    {
        if (context is null) return;

        var resolvedTenantId = tenantContext.TenantId;

        foreach (var entry in context.ChangeTracker.Entries<ITenantEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                {
                    if (entry.Entity.TenantId == Guid.Empty || entry.Entity.TenantId == default)
                    {
                        // Auto-populate; require a resolved context
                        if (!resolvedTenantId.HasValue || resolvedTenantId.Value == Guid.Empty)
                            throw new UnauthorizedAccessException(
                                $"Cannot persist '{entry.Entity.GetType().Name}': no tenant context is active.");

                        entry.Entity.TenantId = resolvedTenantId.Value;
                    }
                    else if (resolvedTenantId.HasValue &&
                             resolvedTenantId.Value != Guid.Empty &&
                             entry.Entity.TenantId != resolvedTenantId.Value)
                    {
                        // Explicitly set to a different tenant – cross-tenant write attempt
                        throw new UnauthorizedAccessException(
                            $"Cannot persist '{entry.Entity.GetType().Name}': " +
                            $"entity TenantId ({entry.Entity.TenantId}) does not match the active tenant ({resolvedTenantId.Value}).");
                    }
                    break;
                }

                case EntityState.Modified:
                case EntityState.Deleted:
                {
                    if (!resolvedTenantId.HasValue || resolvedTenantId.Value == Guid.Empty)
                        throw new UnauthorizedAccessException(
                            $"Cannot modify/delete '{entry.Entity.GetType().Name}': no tenant context is active.");

                    if (entry.Entity.TenantId != resolvedTenantId.Value)
                        throw new UnauthorizedAccessException(
                            $"Cannot modify/delete '{entry.Entity.GetType().Name}': " +
                            $"entity TenantId ({entry.Entity.TenantId}) does not match the active tenant ({resolvedTenantId.Value}).");
                    break;
                }
            }
        }
    }
}
