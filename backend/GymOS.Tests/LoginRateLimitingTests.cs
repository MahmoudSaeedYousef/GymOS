using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Threading.RateLimiting;
using GymOS.Api.RateLimiting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace GymOS.Tests;

/// <summary>
/// Unit tests for the "auth-login" rate limiting policy and its OnRejected handler.
/// These tests operate at the middleware/policy level without spinning up a real HTTP server,
/// so they run fast and require no database connection.
/// </summary>
public class LoginRateLimitingTests
{
    // -----------------------------------------------------------------------
    // Policy constants
    // -----------------------------------------------------------------------

    [Fact]
    public void AuthLoginPolicy_NameConstant_IsCorrect()
    {
        Assert.Equal("auth-login", RateLimitingExtensions.AuthLoginPolicy);
    }

    // -----------------------------------------------------------------------
    // SlidingWindowLimiter — behaviour under the configured limits
    // -----------------------------------------------------------------------

    [Fact]
    public async Task SlidingWindow_AllowsUpToPermitLimit_WithinWindow()
    {
        // Arrange — create a limiter matching the production config
        using var limiter = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            Window            = TimeSpan.FromMinutes(1),
            SegmentsPerWindow = 3,
            PermitLimit       = 5,
            QueueLimit        = 0,
        });

        // Act — acquire exactly PermitLimit leases
        var leases = new List<RateLimitLease>();
        for (int i = 0; i < 5; i++)
        {
            var lease = await limiter.AcquireAsync(permitCount: 1);
            leases.Add(lease);
        }

        // Assert — all 5 succeed
        foreach (var lease in leases)
        {
            Assert.True(lease.IsAcquired, $"Expected lease {leases.IndexOf(lease) + 1} to succeed");
            lease.Dispose();
        }
    }

    [Fact]
    public async Task SlidingWindow_RejectsRequest_BeyondPermitLimit()
    {
        // Arrange
        using var limiter = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            Window            = TimeSpan.FromMinutes(1),
            SegmentsPerWindow = 3,
            PermitLimit       = 5,
            QueueLimit        = 0,
        });

        // Exhaust the 5 permits
        for (int i = 0; i < 5; i++)
        {
            var l = await limiter.AcquireAsync(permitCount: 1);
            l.Dispose();
        }

        // Act — 6th request should be rejected
        using var rejectedLease = await limiter.AcquireAsync(permitCount: 1);

        // Assert
        Assert.False(rejectedLease.IsAcquired, "Expected the 6th request to be rejected");
    }

    // -----------------------------------------------------------------------
    // OnRejected handler — ProblemDetails + headers
    // -----------------------------------------------------------------------

    [Fact]
    public async Task OnRejected_Returns429_WithProblemDetailsAndRetryAfterHeader()
    {
        // Arrange — build a minimal service provider that includes rate limiting
        var services = new ServiceCollection();
        services.AddGymOsRateLimiting();
        var sp = services.BuildServiceProvider();

        var httpContext = BuildHttpContext(sp);
        httpContext.Items["CorrelationId"] = "testcorr1";

        // Build a rejected lease (no metadata for RetryAfter → falls back to 60 s)
        using var limiter = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            Window            = TimeSpan.FromMinutes(1),
            SegmentsPerWindow = 3,
            PermitLimit       = 1,
            QueueLimit        = 0,
        });
        var firstLease  = await limiter.AcquireAsync(1); // consumed
        var rejectedLease = await limiter.AcquireAsync(1); // rejected

        // Wire up the rejection handler directly (same logic as AddGymOsRateLimiting)
        var rateLimitOptions = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<RateLimiterOptions>>().Value;

        // Act
        await rateLimitOptions.OnRejected!(
            new OnRejectedContext { HttpContext = httpContext, Lease = rejectedLease },
            CancellationToken.None);

        // Assert status code
        Assert.Equal(StatusCodes.Status429TooManyRequests, httpContext.Response.StatusCode);

        // Assert Retry-After header present and ≥ 1
        Assert.True(
            httpContext.Response.Headers.TryGetValue("Retry-After", out var retryAfterHeader),
            "Retry-After header must be present");
        Assert.True(
            int.TryParse(retryAfterHeader, out var retryAfterSeconds) && retryAfterSeconds >= 1,
            $"Retry-After must be a positive integer, got: {retryAfterHeader}");

        // Assert response body is ProblemDetails JSON
        httpContext.Response.Body.Position = 0;
        var body = await new StreamReader(httpContext.Response.Body).ReadToEndAsync();
        Assert.Contains("\"status\":429", body);
        Assert.Contains("\"correlationId\"", body);
        Assert.Contains("\"retryAfterSeconds\"", body);
        Assert.Contains("testcorr1", body);
        Assert.Equal("application/problem+json", httpContext.Response.ContentType);

        firstLease.Dispose();
        rejectedLease.Dispose();
    }

    [Fact]
    public async Task OnRejected_EchosCorrelationIdOnResponseHeader()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddGymOsRateLimiting();
        var sp = services.BuildServiceProvider();

        const string corrId = "deadbeef";
        var httpContext = BuildHttpContext(sp);
        httpContext.Items["CorrelationId"] = corrId;

        using var limiter = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            PermitLimit = 1, QueueLimit = 0,
            Window = TimeSpan.FromSeconds(30), SegmentsPerWindow = 1
        });
        var _ = await limiter.AcquireAsync(1);
        var rejected = await limiter.AcquireAsync(1);

        var rateLimitOptions = sp
            .GetRequiredService<Microsoft.Extensions.Options.IOptions<RateLimiterOptions>>().Value;

        // Act
        await rateLimitOptions.OnRejected!(
            new OnRejectedContext { HttpContext = httpContext, Lease = rejected },
            CancellationToken.None);

        // Assert X-Correlation-Id is echoed on response
        Assert.True(httpContext.Response.Headers.TryGetValue("X-Correlation-Id", out var headerVal));
        Assert.Equal(corrId, headerVal.ToString());

        rejected.Dispose();
    }

    [Fact]
    public async Task OnRejected_RetryAfterSeconds_IsAtLeastOne_WhenNoMetadata()
    {
        // Arrange — lease with no RetryAfter metadata → default fallback = 60 s
        var services = new ServiceCollection();
        services.AddGymOsRateLimiting();
        var sp = services.BuildServiceProvider();

        var httpContext = BuildHttpContext(sp);

        using var limiter = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            PermitLimit = 1, QueueLimit = 0,
            Window = TimeSpan.FromSeconds(30), SegmentsPerWindow = 1
        });
        var _ = await limiter.AcquireAsync(1);
        var rejected = await limiter.AcquireAsync(1);

        var rateLimitOptions = sp
            .GetRequiredService<Microsoft.Extensions.Options.IOptions<RateLimiterOptions>>().Value;

        // Act
        await rateLimitOptions.OnRejected!(
            new OnRejectedContext { HttpContext = httpContext, Lease = rejected },
            CancellationToken.None);

        // Parse body — ProblemDetails extensions are merged at the top level in the JSON output
        httpContext.Response.Body.Position = 0;
        var body = await new StreamReader(httpContext.Response.Body).ReadToEndAsync();

        // The body must contain "retryAfterSeconds" at some level
        Assert.Contains("retryAfterSeconds", body);

        // Parse and verify the value is ≥ 1
        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;

        // Try top-level first (camelCase merged extensions), then nested "extensions"
        int retryAfterSeconds;
        if (root.TryGetProperty("retryAfterSeconds", out var topLevel))
        {
            retryAfterSeconds = topLevel.GetInt32();
        }
        else
        {
            var extensions = root.GetProperty("extensions");
            retryAfterSeconds = extensions.GetProperty("retryAfterSeconds").GetInt32();
        }

        Assert.True(retryAfterSeconds >= 1, $"retryAfterSeconds must be ≥ 1, got {retryAfterSeconds}");

        rejected.Dispose();
    }

    // -----------------------------------------------------------------------
    // Partition key — independent limiter instances don't interfere
    // -----------------------------------------------------------------------

    [Fact]
    public async Task DifferentPartitionKeys_HaveIndependentLimits()
    {
        // Arrange — simulate two separate users by giving them distinct limiters
        // (IRL the PartitionedRateLimiter does this per partition key)
        using var limiter1 = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            PermitLimit = 5, QueueLimit = 0,
            Window = TimeSpan.FromMinutes(1), SegmentsPerWindow = 3,
        });
        using var limiter2 = new SlidingWindowRateLimiter(new SlidingWindowRateLimiterOptions
        {
            PermitLimit = 5, QueueLimit = 0,
            Window = TimeSpan.FromMinutes(1), SegmentsPerWindow = 3,
        });

        // Exhaust limiter1 (represents IP A)
        for (int i = 0; i < 5; i++)
            (await limiter1.AcquireAsync(1)).Dispose();

        // limiter2 (represents IP B) must still work
        using var leaseForUser2 = await limiter2.AcquireAsync(1);
        Assert.True(leaseForUser2.IsAcquired,
            "A different client's limiter must remain unaffected by another client hitting their own limit");
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private static DefaultHttpContext BuildHttpContext(IServiceProvider sp)
    {
        var context = new DefaultHttpContext { RequestServices = sp };
        context.Response.Body = new MemoryStream();
        return context;
    }
}
