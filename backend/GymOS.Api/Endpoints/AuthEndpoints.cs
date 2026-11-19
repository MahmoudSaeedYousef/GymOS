using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using GymOS.Application.DTOs.Auth;
using GymOS.Application.Mappers;
using GymOS.Domain.Entities;
using GymOS.Infrastructure.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace GymOS.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Authentication");

        // 1. مسار التسجيل (Register)
        group.MapPost("/register", async (
            RegisterRequest request,
            UserManager<ApplicationUser> userManager,
            GymDbContext dbContext, // <-- حقن الداتابيز
            IConfiguration config) =>
        {
            // 1. إنشاء جيم جديد لصاحب الحساب (Tenant)
            var tenant = new GymTenant
            {
                Name = $"{request.FullName}'s Gym",
                Subdomain = $"gym-{Guid.NewGuid().ToString()[..6]}"
            };
            dbContext.Tenants.Add(tenant);
            await dbContext.SaveChangesAsync();

            // 2. إنشاء المستخدم وربطه بالـ TenantId الجديد
            var user = new ApplicationUser
            {
                UserName = request.PhoneNumber,
                PhoneNumber = request.PhoneNumber,
                FullName = request.FullName,
                SubscriptionEndDate = DateTime.UtcNow.Date.AddDays(30),
                TenantId = tenant.Id // <-- ربط اليوزر بالجيم
            };

            var result = await userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
                return Results.BadRequest(result.Errors);

            var token = GenerateJwtToken(user, config);
            return Results.Ok(new AuthResponse 
            { 
                Token = token, 
                FullName = user.FullName, 
                PhoneNumber = user.PhoneNumber! 
            });
            
        });

        // 2. مسار تسجيل الدخول (Login)
        group.MapPost("/login", async (
            LoginRequest request,
            UserManager<ApplicationUser> userManager,
            IConfiguration config) =>
        {
            // IgnoreQueryFilters() ضرورية هنا لأن اليوزر لسه معندوش Token شايل TenantId
            var user = await userManager.Users
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(u => u.PhoneNumber == request.PhoneNumber);

            if (user is null || !await userManager.CheckPasswordAsync(user, request.Password))
                return Results.Unauthorized();

            var token = GenerateJwtToken(user, config);
            return Results.Ok(new AuthResponse
            {
                Token = token,
                FullName = user.FullName,
                PhoneNumber = user.PhoneNumber!
            });
        });
    }

    // 3. دالة توليد الـ JWT Token
    private static string GenerateJwtToken(ApplicationUser user, IConfiguration config)
    {
        var jwtSettings = config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Role, user.Type.ToString()),
            new("phone_number", user.PhoneNumber ?? ""),
            new("tenant_id", user.TenantId.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: jwtSettings["Issuer"],
            audience: jwtSettings["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7), // التوكن صالح لمدة أسبوع
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}