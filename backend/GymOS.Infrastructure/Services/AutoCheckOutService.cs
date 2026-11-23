namespace GymOS.Infrastructure.Services;

using GymOS.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

public class AutoCheckOutService(
    IGymDbContext dbContext,
    ILogger<AutoCheckOutService> logger) : IAutoCheckOutService
{
    public async Task<int> ProcessAutoCheckOutAsync(DateTime? utcNow = null, CancellationToken cancellationToken = default)
    {
        var now = utcNow ?? DateTime.UtcNow;

        var activeTenants = await dbContext.Tenants
            .IgnoreQueryFilters()
            .Where(t => t.IsActive)
            .ToDictionaryAsync(
                t => t.Id.ToString(),
                t => t.DefaultSessionDurationMinutes > 0 ? t.DefaultSessionDurationMinutes : 180,
                cancellationToken);

        var openRecordsQuery = dbContext.AttendanceRecords
            .IgnoreQueryFilters()
            .Where(a => a.CheckOutTime == null);

        if (activeTenants.Count > 0)
        {
            var activeTenantIds = activeTenants.Keys.ToList();
            openRecordsQuery = openRecordsQuery.Where(a => activeTenantIds.Contains(a.TenantId));
        }

        var openRecords = await openRecordsQuery.ToListAsync(cancellationToken);

        var updatedCount = 0;
        foreach (var record in openRecords)
        {
            var durationMinutes = activeTenants.TryGetValue(record.TenantId, out var dur) ? dur : 180;
            var cutoffTime = now.AddMinutes(-durationMinutes);

            if (record.CheckInTime <= cutoffTime)
            {
                record.CheckOutTime = record.CheckInTime.AddMinutes(durationMinutes);
                updatedCount++;
            }
        }

        if (updatedCount > 0)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
            logger.LogInformation("Auto-checked out {Count} attendance record(s) exceeding session duration.", updatedCount);
        }

        return updatedCount;
    }
}
