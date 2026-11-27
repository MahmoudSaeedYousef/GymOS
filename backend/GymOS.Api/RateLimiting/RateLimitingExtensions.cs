using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;

namespace GymOS.Api.RateLimiting;

/// <summary>
/// Configures all GymOS rate limiting policies.
/// </summary>
public static class RateLimitingExtensions
{
    /// <summary>
    /// Named policy applied to the login endpoint.
    /// Partitioned per: client IP + tenant key + phone/identifier — so a single bad actor
    /// cannot lock out an entire gym network or other staff members.
    /// </summary>
    public const string AuthLoginPolicy = "auth-login";

    /// <summary>
    /// Registers rate limiting services and the "auth-login" sliding-window policy.
    /// </summary>
    public static IServiceCollection AddGymOsRateLimiting(this IServiceCollection services)
    {
        services.AddRateLimiter(options =>
        {
            // ----------------------------------------------------------------
            // "auth-login": 5 permits per 60-second sliding window (3 segments)
            // QueueLimit = 0 → reject immediately when limit is hit (no queuing).
            // ----------------------------------------------------------------
            options.AddPolicy(AuthLoginPolicy, httpContext =>
            {
                var partitionKey = BuildLoginPartitionKey(httpContext);

                return RateLimitPartition.GetSlidingWindowLimiter(
                    partitionKey,
                    _ => new SlidingWindowRateLimiterOptions
                    {
                        Window            = TimeSpan.FromMinutes(1),
                        SegmentsPerWindow = 3,
                        PermitLimit       = 5,
                        QueueLimit        = 0,
                    });
            });

            // ----------------------------------------------------------------
            // Global rejection handler — returns ProblemDetails + Retry-After
            // ----------------------------------------------------------------
            options.OnRejected = async (ctx, cancellationToken) =>
            {
                var httpContext = ctx.HttpContext;

                // Compute Retry-After seconds (at least 1)
                var retryAfter = ctx.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfterTs)
                    ? (int)Math.Ceiling(retryAfterTs.TotalSeconds)
                    : 60;
                retryAfter = Math.Max(retryAfter, 1);

                var correlationId = httpContext.Items["CorrelationId"] as string
                                    ?? httpContext.TraceIdentifier;

                var problemDetails = new ProblemDetails
                {
                    Status = StatusCodes.Status429TooManyRequests,
                    Title  = "Too Many Requests",
                    Detail = "لقد تجاوزت الحد المسموح به من محاولات تسجيل الدخول. يرجى الانتظار قبل المحاولة مجدداً.",
                };
                problemDetails.Extensions["message"]          = problemDetails.Detail;
                problemDetails.Extensions["errorCode"]        = "RATE_LIMIT_EXCEEDED";
                problemDetails.Extensions["correlationId"]    = correlationId;
                problemDetails.Extensions["retryAfterSeconds"] = retryAfter;

                httpContext.Response.StatusCode  = StatusCodes.Status429TooManyRequests;
                httpContext.Response.ContentType = "application/problem+json";
                httpContext.Response.Headers.RetryAfter = retryAfter.ToString();

                // Echo correlation ID on the response
                if (!httpContext.Response.HasStarted)
                    httpContext.Response.Headers["X-Correlation-Id"] = correlationId;

                var json = JsonSerializer.Serialize(
                    problemDetails,
                    new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });

                await httpContext.Response.WriteAsync(json, Encoding.UTF8, cancellationToken);
            };
        });

        return services;
    }

    // -------------------------------------------------------------------------
    // Composite partition key: IP + tenant key + phone/identifier
    // -------------------------------------------------------------------------

    private static string BuildLoginPartitionKey(HttpContext httpContext)
    {
        // 1. Client IP — honours X-Forwarded-For set by ForwardedHeadersMiddleware
        var ip = httpContext.Connection.RemoteIpAddress;
        var ipPart = ip is not null
            ? (ip.IsIPv4MappedToIPv6 ? ip.MapToIPv4() : ip).ToString()
            : "unknown";

        // 2. Tenant identifier (header set by reverse proxy / mobile client)
        //    Falls back gracefully so one header being absent does not break the key.
        var tenantPart = "t0";
        if (httpContext.Request.Headers.TryGetValue("X-Gym-Id", out var gymIdHeader)
            && !string.IsNullOrWhiteSpace(gymIdHeader))
        {
            tenantPart = gymIdHeader.ToString().Trim()[..Math.Min(36, gymIdHeader.ToString().Length)];
        }

        // 3. Phone / identifier — read from query-string or the buffered body form value.
        //    We deliberately do NOT consume the request body stream here (the body will be
        //    read later by model binding). Instead, we try cheap sources only:
        //      a) query string  ?phoneNumber=…
        //      b) route value   {phoneNumber}
        //    If the endpoint uses JSON body, we fall back to "unknown" so the per-IP+tenant
        //    bucket still limits the client without consuming the stream.
        var phonePart = "unknown";
        if (httpContext.Request.Query.TryGetValue("phoneNumber", out var phoneQuery)
            && !string.IsNullOrWhiteSpace(phoneQuery))
        {
            phonePart = Normalize(phoneQuery.ToString());
        }
        else if (httpContext.Request.RouteValues.TryGetValue("phoneNumber", out var routePhone)
                 && routePhone is string routePhoneStr
                 && !string.IsNullOrWhiteSpace(routePhoneStr))
        {
            phonePart = Normalize(routePhoneStr);
        }

        return $"login:{ipPart}:{tenantPart}:{phonePart}";
    }

    /// <summary>
    /// Keeps only digits and '+' and limits length so the key stays bounded.
    /// </summary>
    private static string Normalize(string raw)
    {
        var sb = new StringBuilder(Math.Min(raw.Length, 20));
        foreach (var c in raw)
        {
            if (char.IsDigit(c) || c == '+') sb.Append(c);
            if (sb.Length == 20) break;
        }
        return sb.Length > 0 ? sb.ToString() : "unknown";
    }
}
