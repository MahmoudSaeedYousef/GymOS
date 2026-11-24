using System.Text.Json;
using GymOS.Application.Exceptions;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Serilog;

namespace GymOS.Api.Middleware;

/// <summary>
/// Implements IExceptionHandler (registered via AddExceptionHandler + AddProblemDetails).
/// Maps well-known exceptions to structured ProblemDetails responses while preserving a
/// top-level "message" string in Arabic for backward-compatible mobile clients.
/// </summary>
public sealed class GlobalExceptionHandler(IWebHostEnvironment env) : IExceptionHandler
{
    private static readonly JsonSerializerOptions JsonOpts =
        new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var correlationId = httpContext.Items["CorrelationId"] as string
                            ?? httpContext.TraceIdentifier;
        var tenantId = httpContext.Items["TenantId"] as string
                       ?? httpContext.User?.FindFirst("tenant_id")?.Value
                       ?? "unknown";

        var (statusCode, message, errors) = MapException(exception, env);

        // Log appropriately
        if (exception is OperationCanceledException)
        {
            Log.Information(
                "Request cancelled. CorrelationId={CorrelationId} TenantId={TenantId}",
                correlationId, tenantId);
        }
        else if (statusCode >= 500)
        {
            Log.Error(
                exception,
                "Unhandled exception. CorrelationId={CorrelationId} TenantId={TenantId}",
                correlationId, tenantId);
        }
        else
        {
            Log.Warning(
                "Handled exception {ExceptionType} -> {StatusCode}. CorrelationId={CorrelationId}",
                exception.GetType().Name, statusCode, correlationId);
        }

        // Build the response body — standard ProblemDetails extended with our mobile fields
        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title  = ReasonPhrase(statusCode),
        };

        // Include exception detail only in non-production environments
        if (statusCode >= 500 && (env.IsDevelopment() || env.IsStaging()))
        {
            problemDetails.Detail = exception.ToString();
        }

        // Extensions visible to both old and new clients
        problemDetails.Extensions["message"]   = message;          // Arabic for mobile backward-compat
        problemDetails.Extensions["errorCode"]  = ErrorCode(exception);
        problemDetails.Extensions["traceId"]    = correlationId;
        if (errors != null)
            problemDetails.Extensions["errors"] = errors;

        httpContext.Response.StatusCode  = statusCode;
        httpContext.Response.ContentType = "application/problem+json";

        // Echo correlation ID on the response header (belt-and-suspenders in case
        // CorrelationIdMiddleware's OnStarting hasn't fired yet due to short-circuit)
        if (!httpContext.Response.HasStarted)
            httpContext.Response.Headers["X-Correlation-Id"] = correlationId;

        await httpContext.Response.WriteAsJsonAsync(problemDetails, JsonOpts, cancellationToken);
        return true;
    }

    // -----------------------------------------------------------------------
    // Mapping logic
    // -----------------------------------------------------------------------

    private static (int StatusCode, string Message, object? Errors) MapException(
        Exception exception,
        IWebHostEnvironment env)
    {
        return exception switch
        {
            ValidationException ve => (
                StatusCodes.Status400BadRequest,
                ve.Message.Length > 0 ? ve.Message : "بيانات غير صحيحة. يرجى مراجعة الحقول المدخلة.",
                (object)ve.Errors),

            UnauthorizedAccessException => (
                StatusCodes.Status403Forbidden,
                "غير مصرح لك بتنفيذ هذا الإجراء.",
                null),

            KeyNotFoundException => (
                StatusCodes.Status404NotFound,
                "العنصر المطلوب غير موجود.",
                null),

            DbUpdateException { InnerException: PostgresException pg } => MapPostgresException(pg),

            DbUpdateException => (
                StatusCodes.Status500InternalServerError,
                "حدث خطأ أثناء حفظ البيانات. يرجى المحاولة مرة أخرى.",
                null),

            OperationCanceledException => (
                499,   // Client Closed Request (non-standard but widely recognised)
                "تم إلغاء الطلب.",
                null),

            _ => (
                StatusCodes.Status500InternalServerError,
                "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني.",
                null),
        };
    }

    private static (int StatusCode, string Message, object? Errors) MapPostgresException(
        PostgresException pg)
    {
        return pg.SqlState switch
        {
            "23505" => (  // unique_violation
                StatusCodes.Status409Conflict,
                "البيانات المدخلة موجودة مسبقاً. يرجى استخدام قيم مختلفة.",
                null),

            "23503" => (  // foreign_key_violation
                StatusCodes.Status400BadRequest,
                "لا يمكن تنفيذ العملية لأن البيانات المرجعية غير موجودة.",
                null),

            _ => (
                StatusCodes.Status500InternalServerError,
                "حدث خطأ في قاعدة البيانات. يرجى المحاولة مرة أخرى.",
                null),
        };
    }

    private static string ErrorCode(Exception ex) => ex switch
    {
        ValidationException         => "VALIDATION_ERROR",
        UnauthorizedAccessException => "FORBIDDEN",
        KeyNotFoundException        => "NOT_FOUND",
        DbUpdateException { InnerException: PostgresException { SqlState: "23505" } } => "CONFLICT",
        DbUpdateException { InnerException: PostgresException { SqlState: "23503" } } => "REFERENCE_ERROR",
        DbUpdateException           => "DB_ERROR",
        OperationCanceledException  => "REQUEST_CANCELLED",
        _                           => "INTERNAL_ERROR",
    };

    private static string ReasonPhrase(int statusCode) => statusCode switch
    {
        400 => "Bad Request",
        403 => "Forbidden",
        404 => "Not Found",
        409 => "Conflict",
        499 => "Client Closed Request",
        500 => "Internal Server Error",
        503 => "Service Unavailable",
        _   => "Error",
    };
}
