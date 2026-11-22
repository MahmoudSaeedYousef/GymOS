using System.Text;
using GymOS.Api.Endpoints;
using GymOS.Api.Middleware;
using GymOS.Application.Features.Plans.Commands.CreatePlan;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using GymOS.Infrastructure.Data;
using GymOS.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<GymDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<GymDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddScoped<IFileStorageService, LocalFileStorageService>();
builder.Services.AddMemoryCache();
builder.Services.AddScoped<ICacheService, InMemoryCacheService>();
builder.Services.AddScoped<IGymHistorySeeder, GymHistorySeeder>();

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
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.UseIdempotency();

app.MapAuthEndpoints();
app.MapGymEndpoints();
app.MapAttendanceEndpoints();
app.MapPaymentsEndpoints();
app.MapDashboardEndpoints();
app.MapPlansEndpoints();
app.MapVisitEndpoints();
app.MapDevEndpoints();

app.Run();