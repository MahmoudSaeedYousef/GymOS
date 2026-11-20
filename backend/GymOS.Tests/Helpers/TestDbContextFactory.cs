using GymOS.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace GymOS.Tests.Helpers;

public static class TestDbContextFactory
{
    public static GymDbContext Create(string? tenantId = null, string? dbName = null)
    {
        var options = new DbContextOptionsBuilder<GymDbContext>()
            .UseInMemoryDatabase(dbName ?? Guid.NewGuid().ToString())
            .ConfigureWarnings(x => x.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        var tenantService = new TestTenantService(tenantId ?? Guid.NewGuid().ToString());
        var context = new GymDbContext(options, tenantService);
        context.Database.EnsureCreated();
        return context;
    }
}
