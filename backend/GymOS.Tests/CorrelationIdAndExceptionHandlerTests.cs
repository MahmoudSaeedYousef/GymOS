using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using GymOS.Api.Middleware;
using GymOS.Application.Exceptions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace GymOS.Tests;

/// <summary>
/// Unit-level tests for CorrelationIdMiddleware and GlobalExceptionHandler logic.
/// </summary>
public class CorrelationIdMiddlewareTests
{
    // -----------------------------------------------------------------------
    // CorrelationIdMiddleware
    // -----------------------------------------------------------------------

    [Fact]
    public async Task CorrelationId_MissingFromRequest_GeneratesEightCharHex()
    {
        string? capturedId = null;
        RequestDelegate next = ctx =>
        {
            capturedId = ctx.Items["CorrelationId"] as string;
            return Task.CompletedTask;
        };

        var middleware = new CorrelationIdMiddleware(next);
        var context = new DefaultHttpContext
        {
            RequestServices = new ServiceCollection().BuildServiceProvider()
        };
        context.Response.Body = new System.IO.MemoryStream();

        await middleware.InvokeAsync(context);

        Assert.NotNull(capturedId);
        Assert.Equal(8, capturedId!.Length);
        Assert.True(IsHex(capturedId), $"Expected hex string, got: {capturedId}");
    }

    [Fact]
    public async Task CorrelationId_ProvidedInRequest_IsEchoedOnResponse()
    {
        const string incomingId = "cafebabe";
        // Write response body so that OnStarting callbacks fire
        RequestDelegate next = async ctx =>
        {
            await ctx.Response.WriteAsync("ok");
        };

        var middleware = new CorrelationIdMiddleware(next);
        var context = new DefaultHttpContext
        {
            RequestServices = new ServiceCollection().BuildServiceProvider()
        };
        context.Request.Headers["X-Correlation-Id"] = incomingId;
        context.Response.Body = new System.IO.MemoryStream();

        await middleware.InvokeAsync(context);

        // Items are always set regardless of OnStarting
        Assert.Equal(incomingId, context.Items["CorrelationId"]);
        // Header is set via OnStarting — fires because next wrote to the response body
        Assert.Equal(incomingId, context.Response.Headers["X-Correlation-Id"].ToString());
    }

    [Fact]
    public async Task CorrelationId_BlankHeader_GeneratesNewId()
    {
        RequestDelegate next = _ => Task.CompletedTask;

        var middleware = new CorrelationIdMiddleware(next);
        var context = new DefaultHttpContext
        {
            RequestServices = new ServiceCollection().BuildServiceProvider()
        };
        context.Request.Headers["X-Correlation-Id"] = "   ";
        context.Response.Body = new System.IO.MemoryStream();

        await middleware.InvokeAsync(context);

        var generatedId = context.Items["CorrelationId"] as string;
        Assert.NotNull(generatedId);
        Assert.Equal(8, generatedId!.Length);
        Assert.NotEqual("   ", generatedId);
    }

    // -----------------------------------------------------------------------
    // ValidationException
    // -----------------------------------------------------------------------

    [Fact]
    public void ValidationException_WithErrors_StoresErrors()
    {
        var errors = new Dictionary<string, string[]>
        {
            { "phoneNumber", new[] { "رقم الهاتف مطلوب." } }
        };

        var ex = new ValidationException("بيانات غير صحيحة.", errors);

        Assert.Equal("VALIDATION_ERROR", GetErrorCode(ex));
        Assert.True(ex.Errors.ContainsKey("phoneNumber"));
        Assert.Equal("رقم الهاتف مطلوب.", ex.Errors["phoneNumber"][0]);
    }

    [Fact]
    public void ValidationException_WithoutMessage_UsesArabicDefault()
    {
        var errors = new Dictionary<string, string[]>
        {
            { "name", new[] { "الاسم مطلوب." } }
        };

        var ex = new ValidationException(errors);

        Assert.Contains("بيانات", ex.Message); // Arabic default message
    }

    // -----------------------------------------------------------------------
    // GlobalExceptionHandler — status code mapping
    // -----------------------------------------------------------------------

    [Theory]
    [InlineData(typeof(KeyNotFoundException), 404)]
    [InlineData(typeof(UnauthorizedAccessException), 403)]
    [InlineData(typeof(OperationCanceledException), 499)]
    public async Task GlobalExceptionHandler_MapsStatusCodesCorrectly(Type exceptionType, int expectedStatus)
    {
        var exception = (Exception)Activator.CreateInstance(exceptionType)!;
        var env = CreateFakeEnv("Production");

        var handler = new GlobalExceptionHandler(env);
        var context = BuildHttpContext();

        var handled = await handler.TryHandleAsync(context, exception, default);

        Assert.True(handled);
        Assert.Equal(expectedStatus, context.Response.StatusCode);
    }

    [Fact]
    public async Task GlobalExceptionHandler_ValidationException_Returns400WithErrors()
    {
        var errors = new Dictionary<string, string[]> { { "name", new[] { "مطلوب." } } };
        var ex = new ValidationException("بيانات غير صحيحة.", errors);
        var env = CreateFakeEnv("Production");

        var handler = new GlobalExceptionHandler(env);
        var context = BuildHttpContext();

        var handled = await handler.TryHandleAsync(context, ex, default);

        Assert.True(handled);
        Assert.Equal(400, context.Response.StatusCode);
    }

    [Fact]
    public async Task GlobalExceptionHandler_UnhandledException_Returns500()
    {
        var ex = new InvalidOperationException("something broke");
        var env = CreateFakeEnv("Production");

        var handler = new GlobalExceptionHandler(env);
        var context = BuildHttpContext();

        var handled = await handler.TryHandleAsync(context, ex, default);

        Assert.True(handled);
        Assert.Equal(500, context.Response.StatusCode);
    }

    [Fact]
    public async Task GlobalExceptionHandler_EchosCorrelationIdOnResponse()
    {
        const string corrId = "deadbeef";
        var ex = new KeyNotFoundException();
        var env = CreateFakeEnv("Production");

        var handler = new GlobalExceptionHandler(env);
        var context = BuildHttpContext();
        context.Items["CorrelationId"] = corrId;

        await handler.TryHandleAsync(context, ex, default);

        // The body should contain the traceId value
        context.Response.Body.Position = 0;
        var body = await new System.IO.StreamReader(context.Response.Body).ReadToEndAsync();
        Assert.Contains(corrId, body);
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private static bool IsHex(string s)
        => s.ToLowerInvariant().All(c => "0123456789abcdef".Contains(c));

    private static string GetErrorCode(Exception ex) => ex switch
    {
        ValidationException         => "VALIDATION_ERROR",
        UnauthorizedAccessException => "FORBIDDEN",
        KeyNotFoundException        => "NOT_FOUND",
        OperationCanceledException  => "REQUEST_CANCELLED",
        _                           => "INTERNAL_ERROR",
    };

    private static DefaultHttpContext BuildHttpContext()
    {
        var context = new DefaultHttpContext
        {
            RequestServices = new ServiceCollection().BuildServiceProvider()
        };
        context.Response.Body = new System.IO.MemoryStream();
        return context;
    }

    private static Microsoft.AspNetCore.Hosting.IWebHostEnvironment CreateFakeEnv(string envName)
    {
        var env = new FakeWebHostEnvironment(envName);
        return env;
    }

    private sealed class FakeWebHostEnvironment(string envName)
        : Microsoft.AspNetCore.Hosting.IWebHostEnvironment
    {
        public string EnvironmentName { get; set; } = envName;
        public string ApplicationName { get; set; } = "GymOS.Api";
        public string WebRootPath { get; set; } = string.Empty;
        public Microsoft.Extensions.FileProviders.IFileProvider WebRootFileProvider { get; set; }
            = new Microsoft.Extensions.FileProviders.NullFileProvider();
        public string ContentRootPath { get; set; } = string.Empty;
        public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; }
            = new Microsoft.Extensions.FileProviders.NullFileProvider();
    }
}
