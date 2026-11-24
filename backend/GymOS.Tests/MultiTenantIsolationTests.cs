using System.Security.Claims;
using GymOS.Api.Middleware;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using GymOS.Infrastructure.Data;
using GymOS.Infrastructure.Services;
using GymOS.Tests.Helpers;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace GymOS.Tests;

public class MultiTenantIsolationTests
{
    private static (DefaultHttpContext HttpContext, GymDbContext DbContext, ITenantContext TenantContext) CreateTestHttpContext(
        Guid? tenantIdClaim = null,
        string? spoofedTenantHeader = null,
        bool isAuthenticated = true,
        bool seedActiveTenant = true,
        string? dbName = null)
    {
        var services = new ServiceCollection();
        var databaseName = dbName ?? Guid.NewGuid().ToString();

        var dbOptions = new DbContextOptionsBuilder<GymDbContext>()
            .UseInMemoryDatabase(databaseName)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        var tenantContext = new TenantContext();
        services.AddSingleton<ITenantContext>(tenantContext);
        services.AddMemoryCache();

        var tenantService = new TestTenantService(tenantIdClaim?.ToString());
        services.AddSingleton<ICurrentTenantService>(tenantService);

        var dbContext = new GymDbContext(dbOptions, tenantService);
        dbContext.Database.EnsureCreated();
        services.AddSingleton(dbContext);
        services.AddSingleton<IGymDbContext>(dbContext);

        if (seedActiveTenant && tenantIdClaim.HasValue)
        {
            dbContext.Tenants.Add(new GymTenant
            {
                Id = tenantIdClaim.Value,
                Name = "Test Tenant",
                Subdomain = "test",
                IsActive = true
            });
            dbContext.SaveChanges();
        }

        var serviceProvider = services.BuildServiceProvider();

        var httpContext = new DefaultHttpContext
        {
            RequestServices = serviceProvider
        };

        if (isAuthenticated)
        {
            var claims = new List<Claim>();
            if (tenantIdClaim.HasValue)
            {
                claims.Add(new Claim("tenant_id", tenantIdClaim.Value.ToString()));
            }

            httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
        }

        if (!string.IsNullOrEmpty(spoofedTenantHeader))
        {
            httpContext.Request.Headers["X-Tenant-Id"] = spoofedTenantHeader;
        }

        return (httpContext, dbContext, tenantContext);
    }

    private static GymDbContext CreateGuardedDbContext(
        ITenantContext tenantContext,
        ICurrentTenantService tenantService,
        string dbName)
    {
        var interceptor = new TenantSaveChangesInterceptor(tenantContext);
        var options = new DbContextOptionsBuilder<GymDbContext>()
            .UseInMemoryDatabase(dbName)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .AddInterceptors(interceptor)
            .Options;

        var context = new GymDbContext(options, tenantService);
        context.Database.EnsureCreated();
        return context;
    }

    [Fact]
    public async Task AuthenticatedRequest_LackingValidTenantIdClaim_IsRejectedWith403Forbidden()
    {
        // Arrange
        var (context, _, _) = CreateTestHttpContext(tenantIdClaim: null, isAuthenticated: true);
        var nextExecuted = false;
        RequestDelegate next = _ =>
        {
            nextExecuted = true;
            return Task.CompletedTask;
        };

        var middleware = new TenantMiddleware(next, NullLogger<TenantMiddleware>.Instance);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        Assert.False(nextExecuted);
        Assert.Equal(StatusCodes.Status403Forbidden, context.Response.StatusCode);
        Assert.NotNull(context.Response.ContentType);
        Assert.StartsWith("application/json", context.Response.ContentType);
    }

    [Fact]
    public async Task SpoofedXTenantIdHeader_NeverOverridesAuthenticatedJwtTenantId()
    {
        // Arrange
        var legitimateTenantId = Guid.NewGuid();
        var spoofedTenantId = Guid.NewGuid();

        var (context, _, tenantContext) = CreateTestHttpContext(
            tenantIdClaim: legitimateTenantId,
            spoofedTenantHeader: spoofedTenantId.ToString(),
            isAuthenticated: true,
            seedActiveTenant: true);

        var nextExecuted = false;
        RequestDelegate next = _ =>
        {
            nextExecuted = true;
            return Task.CompletedTask;
        };

        var middleware = new TenantMiddleware(next, NullLogger<TenantMiddleware>.Instance);

        // Act
        await middleware.InvokeAsync(context);

        // Assert
        Assert.True(nextExecuted);
        Assert.Equal(StatusCodes.Status200OK, context.Response.StatusCode);
        Assert.True(tenantContext.IsResolved);
        Assert.Equal(legitimateTenantId, tenantContext.TenantId);
        Assert.NotEqual(spoofedTenantId, tenantContext.TenantId);
    }

    [Fact]
    public void TenantSaveChangesInterceptor_BlocksCrossTenantWrites_AndAutoAssignsTenantIdOnAdd()
    {
        // Arrange
        var tenantA = Guid.NewGuid();
        var tenantB = Guid.NewGuid();
        var dbName = $"IsolationDb_{Guid.NewGuid():N}";

        var tenantContext = new TenantContext();
        var tenantService = new TestTenantService(tenantA.ToString());
        using var db = CreateGuardedDbContext(tenantContext, tenantService, dbName);

        // Scenario 1: Auto-assigns active ITenantContext.TenantId on new records with default TenantId
        tenantContext.SetTenantId(tenantA);
        var planA = new Plan
        {
            Name = "Gold Membership",
            Price = 100m,
            DurationInDays = 30
        };
        db.Plans.Add(planA);
        db.SaveChanges();

        Assert.Equal(tenantA, planA.TenantId);

        // Scenario 2: Blocks adding a record with explicit mismatched TenantId
        var mismatchedPlan = new Plan
        {
            TenantId = tenantB,
            Name = "Mismatched Plan",
            Price = 50m,
            DurationInDays = 30
        };
        db.Plans.Add(mismatchedPlan);
        var addEx = Assert.Throws<UnauthorizedAccessException>(() => db.SaveChanges());
        Assert.Contains("does not match the active tenant", addEx.Message);

        // Detach mismatched entity to leave change tracker clean
        db.Entry(mismatchedPlan).State = EntityState.Detached;

        // Scenario 3: Switch context to Tenant B and attempt to modify Tenant A's record
        tenantContext.SetTenantId(tenantB);
        planA.Price = 200m;
        db.Entry(planA).State = EntityState.Modified;

        var modEx = Assert.Throws<UnauthorizedAccessException>(() => db.SaveChanges());
        Assert.Contains("does not match the active tenant", modEx.Message);

        // Scenario 4: Switch context to Tenant B and attempt to delete Tenant A's record
        db.Entry(planA).State = EntityState.Deleted;
        var delEx = Assert.Throws<UnauthorizedAccessException>(() => db.SaveChanges());
        Assert.Contains("does not match the active tenant", delEx.Message);
    }

    [Fact]
    public async Task TenantACannotReadUpdateOrDelete_TenantBRecords_WhenSharingSameDatabase()
    {
        // Arrange
        var tenantA = Guid.NewGuid();
        var tenantB = Guid.NewGuid();
        var dbName = $"SharedDb_{Guid.NewGuid():N}";

        var tenantAContext = new TenantContext();
        tenantAContext.SetTenantId(tenantA);
        var tenantAService = new TestTenantService(tenantA.ToString());

        var tenantBContext = new TenantContext();
        tenantBContext.SetTenantId(tenantB);
        var tenantBService = new TestTenantService(tenantB.ToString());

        // Seed data for Tenant B using Tenant B's context
        Guid tenantBPlanId;
        using (var dbB = CreateGuardedDbContext(tenantBContext, tenantBService, dbName))
        {
            var planB = new Plan
            {
                Name = "Tenant B Exclusive Plan",
                Price = 500m,
                DurationInDays = 90
            };
            dbB.Plans.Add(planB);
            await dbB.SaveChangesAsync();
            tenantBPlanId = planB.Id;
        }

        // Act & Assert under Tenant A's scope
        using (var dbA = CreateGuardedDbContext(tenantAContext, tenantAService, dbName))
        {
            // 1. Tenant A cannot READ Tenant B's records (Filtered out by QueryFilter)
            var visiblePlans = await dbA.Plans.ToListAsync();
            Assert.Empty(visiblePlans);

            var directLookup = await dbA.Plans.FirstOrDefaultAsync(p => p.Id == tenantBPlanId);
            Assert.Null(directLookup);

            // 2. Tenant A cannot UPDATE Tenant B's record even if attempted via detached entity / IgnoreQueryFilters
            var untrackedPlanB = await dbA.Plans.IgnoreQueryFilters().FirstAsync(p => p.Id == tenantBPlanId);
            Assert.Equal(tenantB, untrackedPlanB.TenantId);

            untrackedPlanB.Price = 1m;
            dbA.Plans.Update(untrackedPlanB);

            await Assert.ThrowsAsync<UnauthorizedAccessException>(() => dbA.SaveChangesAsync());

            // 3. Tenant A cannot DELETE Tenant B's record
            dbA.Entry(untrackedPlanB).State = EntityState.Deleted;
            await Assert.ThrowsAsync<UnauthorizedAccessException>(() => dbA.SaveChangesAsync());
        }
    }
}
