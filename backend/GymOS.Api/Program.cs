using System.Text;
using GymOS.Api.Endpoints;
using GymOS.Api.Middleware;
using GymOS.Application.Features.Plans.Commands.CreatePlan;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using GymOS.Infrastructure.BackgroundJobs;
using GymOS.Infrastructure.Data;
using GymOS.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
    .CreateBootstrapLogger();

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((ctx, services, cfg) => cfg
    .ReadFrom.Configuration(ctx.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {CorrelationId} {TenantId} {Message:lj}{NewLine}{Exception}"));

// Global exception handler (IExceptionHandler + ProblemDetails)
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddDbContext<GymDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
// Register ITenantContext / TenantContext as Scoped (one per HTTP request / DI scope)
builder.Services.AddScoped<ITenantContext, TenantContext>();

// Register the write-guard interceptor as Scoped so it can depend on ITenantContext
builder.Services.AddScoped<TenantSaveChangesInterceptor>();

builder.Services.AddDbContext<GymDbContext>((sp, options) =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"));
    options.AddInterceptors(sp.GetRequiredService<TenantSaveChangesInterceptor>());
});

builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<GymDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddScoped<IFileStorageService, LocalFileStorageService>();
builder.Services.AddMemoryCache();
builder.Services.AddScoped<ICacheService, InMemoryCacheService>();
builder.Services.AddScoped<IGymHistorySeeder, GymHistorySeeder>();
builder.Services.AddScoped<IAutoCheckOutService, AutoCheckOutService>();
builder.Services.AddHostedService<AutoCheckOutBackgroundService>();

var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = jwtSettings["Key"] ?? "GymOSSuperSecretKeyForJwtAuthenticationWhichMustBeAtLeast32Chars!";

builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
        };
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                Console.WriteLine($"JWT Auth Failed: {context.Exception.Message}");
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentTenantService, CurrentTenantService>();
builder.Services.AddScoped<IGymDbContext>(sp => sp.GetRequiredService<GymDbContext>());
builder.Services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(CreatePlanCommand).Assembly));
var uploadsDirectory = Path.Combine(builder.Environment.ContentRootPath, "wwwroot", "uploads");
if (!Directory.Exists(uploadsDirectory))
{
    Directory.CreateDirectory(uploadsDirectory);
}

var app = builder.Build();
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<GymDbContext>();
    await dbContext.Database.MigrateAsync();
}

app.UseExceptionHandler();     // IExceptionHandler pipeline (GlobalExceptionHandler)
app.UseStaticFiles();
app.UseCorrelationId();        // Must come early so LogContext is enriched for all subsequent middleware
app.UseAuthentication();
app.UseTenantIsolation(); // Must be after UseAuthentication, before UseAuthorization
app.UseAuthorization();
app.UseIdempotency();

app.MapHealthEndpoints();      // GET /health  — anonymous, no sensitive details
app.MapAuthEndpoints();
app.MapGymEndpoints();
app.MapAttendanceEndpoints();
app.MapPaymentsEndpoints();
app.MapDashboardEndpoints();
app.MapPlansEndpoints();
app.MapVisitEndpoints();
app.MapDevEndpoints();

app.Run();