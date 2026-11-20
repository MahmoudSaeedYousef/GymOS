using System.Security.Claims;
using System.Text;
using GymOS.Api.Middleware;
using GymOS.Application.Interfaces;
using GymOS.Infrastructure.Data;
using GymOS.Tests.Helpers;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace GymOS.Tests;

public class IdempotencyMiddlewareTests
{
    private (GymDbContext DbContext, ServiceProvider ServiceProvider) CreateContextAndProvider(Guid gymId, string? dbName = null)
    {
        var services = new ServiceCollection();
        var db = TestDbContextFactory.Create(gymId.ToString(), dbName);
        var tenantService = new TestTenantService(gymId.ToString());

        services.AddSingleton<IGymDbContext>(db);
        services.AddSingleton<GymDbContext>(db);
        services.AddSingleton<ICurrentTenantService>(tenantService);

        return (db, services.BuildServiceProvider());
    }

    [Fact]
    public async Task SamePostTwiceWithSameKey_ExecutesOnce_ReturnsExactResponseWithReplayHeader()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var idempotencyKey = $"idem-{Guid.NewGuid():N}";
        var dbName = $"IdemDb_{Guid.NewGuid():N}";
        var (dbContext, serviceProvider) = CreateContextAndProvider(gymId, dbName);

        var executionCount = 0;
        RequestDelegate next = async (ctx) =>
        {
            executionCount++;
            ctx.Response.StatusCode = StatusCodes.Status201Created;
            ctx.Response.ContentType = "application/json";
            var json = "{\"id\":\"" + Guid.NewGuid() + "\",\"status\":\"Created\"}";
            await ctx.Response.WriteAsync(json, Encoding.UTF8);
        };

        var middleware = new IdempotencyMiddleware(next);

        // Act 1: First call
        var context1 = new DefaultHttpContext
        {
            RequestServices = serviceProvider
        };
        context1.Request.Method = "POST";
        context1.Request.Path = "/api/gym/members";
        context1.Request.Headers["X-Idempotency-Key"] = idempotencyKey;
        context1.User = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim("tenant_id", gymId.ToString())
        }, "TestAuth"));

        var responseBodyStream1 = new MemoryStream();
        context1.Response.Body = responseBodyStream1;

        await middleware.InvokeAsync(context1);

        responseBodyStream1.Position = 0;
        var firstResponseBody = await new StreamReader(responseBodyStream1).ReadToEndAsync();

        // Assert 1: First call executes handler and caches response
        Assert.Equal(1, executionCount);
        Assert.Equal(StatusCodes.Status201Created, context1.Response.StatusCode);
        Assert.False(context1.Response.Headers.ContainsKey("X-Idempotent-Replay"));
        Assert.NotEmpty(firstResponseBody);

        var records = await dbContext.IdempotencyRecords.IgnoreQueryFilters().ToListAsync();
        Assert.Single(records);
        Assert.Equal(gymId, records[0].GymId);
        Assert.Equal(idempotencyKey, records[0].IdempotencyKey);
        Assert.Equal(StatusCodes.Status201Created, records[0].StatusCode);
        Assert.Equal(firstResponseBody, records[0].ResponseBody);

        // Act 2: Second call with the exact same X-Idempotency-Key
        var context2 = new DefaultHttpContext
        {
            RequestServices = serviceProvider
        };
        context2.Request.Method = "POST";
        context2.Request.Path = "/api/gym/members";
        context2.Request.Headers["X-Idempotency-Key"] = idempotencyKey;
        context2.User = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim("tenant_id", gymId.ToString())
        }, "TestAuth"));

        var responseBodyStream2 = new MemoryStream();
        context2.Response.Body = responseBodyStream2;

        await middleware.InvokeAsync(context2);

        responseBodyStream2.Position = 0;
        var secondResponseBody = await new StreamReader(responseBodyStream2).ReadToEndAsync();

        // Assert 2: Handler was NOT re-executed, exact same response returned with X-Idempotent-Replay: true
        Assert.Equal(1, executionCount); // Still 1!
        Assert.Equal(StatusCodes.Status201Created, context2.Response.StatusCode);
        Assert.True(context2.Response.Headers.ContainsKey("X-Idempotent-Replay"));
        Assert.Equal("true", context2.Response.Headers["X-Idempotent-Replay"]);
        Assert.Equal(firstResponseBody, secondResponseBody);

        // Ensure only 1 database row exists
        var finalRecordCount = await dbContext.IdempotencyRecords.IgnoreQueryFilters().CountAsync();
        Assert.Equal(1, finalRecordCount);
    }

    [Fact]
    public async Task MissingIdempotencyKey_PassesThroughNormallyWithoutCaching()
    {
        var gymId = Guid.NewGuid();
        var (dbContext, serviceProvider) = CreateContextAndProvider(gymId);

        var executionCount = 0;
        RequestDelegate next = async (ctx) =>
        {
            executionCount++;
            ctx.Response.StatusCode = StatusCodes.Status200OK;
            await ctx.Response.WriteAsync("{\"ok\":true}");
        };

        var middleware = new IdempotencyMiddleware(next);

        var context = new DefaultHttpContext { RequestServices = serviceProvider };
        context.Request.Method = "POST";
        context.Request.Path = "/api/attendance/check-in";
        context.User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("tenant_id", gymId.ToString()) }, "TestAuth"));
        context.Response.Body = new MemoryStream();

        await middleware.InvokeAsync(context);

        Assert.Equal(1, executionCount);
        Assert.False(context.Response.Headers.ContainsKey("X-Idempotent-Replay"));
        var recordsCount = await dbContext.IdempotencyRecords.IgnoreQueryFilters().CountAsync();
        Assert.Equal(0, recordsCount);
    }

    [Fact]
    public async Task InternalServerError_IsNotCached()
    {
        var gymId = Guid.NewGuid();
        var idempotencyKey = $"error-{Guid.NewGuid():N}";
        var (dbContext, serviceProvider) = CreateContextAndProvider(gymId);

        RequestDelegate next = async (ctx) =>
        {
            ctx.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await ctx.Response.WriteAsync("{\"error\":\"Database transient error\"}");
        };

        var middleware = new IdempotencyMiddleware(next);

        var context = new DefaultHttpContext { RequestServices = serviceProvider };
        context.Request.Method = "POST";
        context.Request.Path = "/api/attendance/check-in";
        context.Request.Headers["X-Idempotency-Key"] = idempotencyKey;
        context.User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("tenant_id", gymId.ToString()) }, "TestAuth"));
        context.Response.Body = new MemoryStream();

        await middleware.InvokeAsync(context);

        Assert.Equal(StatusCodes.Status500InternalServerError, context.Response.StatusCode);
        var recordExists = await dbContext.IdempotencyRecords.IgnoreQueryFilters().AnyAsync();
        Assert.False(recordExists);
    }

    [Fact]
    public async Task SameKeyAcrossDifferentGyms_DoNotCollide()
    {
        var gym1 = Guid.NewGuid();
        var gym2 = Guid.NewGuid();
        var sharedKey = "shared-key-across-tenants";
        var dbName = $"TenantsDb_{Guid.NewGuid():N}";

        var (db1, sp1) = CreateContextAndProvider(gym1, dbName);
        var (_, sp2) = CreateContextAndProvider(gym2, dbName);

        var executionCount = 0;
        RequestDelegate next = async (ctx) =>
        {
            executionCount++;
            ctx.Response.StatusCode = StatusCodes.Status200OK;
            await ctx.Response.WriteAsync("{\"tenant\":\"" + ctx.User.FindFirstValue("tenant_id") + "\"}");
        };

        var middleware = new IdempotencyMiddleware(next);

        // Call for Gym 1
        var ctx1 = new DefaultHttpContext { RequestServices = sp1 };
        ctx1.Request.Method = "POST";
        ctx1.Request.Path = "/api/gym/members";
        ctx1.Request.Headers["X-Idempotency-Key"] = sharedKey;
        ctx1.User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("tenant_id", gym1.ToString()) }, "TestAuth"));
        ctx1.Response.Body = new MemoryStream();
        await middleware.InvokeAsync(ctx1);

        // Call for Gym 2 with the same key
        var ctx2 = new DefaultHttpContext { RequestServices = sp2 };
        ctx2.Request.Method = "POST";
        ctx2.Request.Path = "/api/gym/members";
        ctx2.Request.Headers["X-Idempotency-Key"] = sharedKey;
        ctx2.User = new ClaimsPrincipal(new ClaimsIdentity(new[] { new Claim("tenant_id", gym2.ToString()) }, "TestAuth"));
        ctx2.Response.Body = new MemoryStream();
        await middleware.InvokeAsync(ctx2);

        // Both calls should have executed (executionCount == 2) because GymIds differ!
        Assert.Equal(2, executionCount);

        var records = await db1.IdempotencyRecords.IgnoreQueryFilters().ToListAsync();
        Assert.Equal(2, records.Count);
        Assert.Contains(records, r => r.GymId == gym1);
        Assert.Contains(records, r => r.GymId == gym2);
    }
}
