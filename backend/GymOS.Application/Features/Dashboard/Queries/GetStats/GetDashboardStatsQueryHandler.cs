using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Dashboard.Queries.GetStats;


public class GetDashboardStatsQueryHandler(IGymDbContext context) : IRequestHandler<GetDashboardStatsQuery, DashboardStatsDto>
{
    public async Task<DashboardStatsDto> Handle(GetDashboardStatsQuery request, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var today = now.Date;
        var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        // بفضل الـ Global Query Filters كل ده متفلتر بالـ TenantId أوتوماتيك!
        
        var activeMembers = await context.Users
            .CountAsync(u => u.SubscriptionEndDate >= now, cancellationToken);
            
        // استبعاد الضيوف من عداد الاشتراكات المنتهية
        var expiredMembers = await context.Users
            .CountAsync(u => !u.IsGuest && u.SubscriptionEndDate < now, cancellationToken);

        
        var todayCheckIns = await context.AttendanceRecords.Where(a => a.CheckInTime >= today).Select(c=>c.MemberId).Distinct().CountAsync(cancellationToken: cancellationToken);
            
        var todayRevenue = await context.PaymentRecords
            .Where(p => p.PaymentDate >= today)
            .SumAsync(p => p.Amount, cancellationToken);

        var monthlyRevenue = await context.PaymentRecords
            .Where(p => p.PaymentDate >= startOfMonth)
            .SumAsync(p => p.Amount, cancellationToken);
        
        var monthlyDropInRevenue = await context.PaymentRecords
            .Where(p => p.PaymentDate >= startOfMonth && p.IsDropIn)
            .SumAsync(p => p.Amount, cancellationToken);
        
        var sessionMinutes = await context.Tenants
            .Select(t => (int?)t.DefaultSessionDurationMinutes)
            .FirstOrDefaultAsync(cancellationToken) ?? 120;

        var cutoffTime = now.AddMinutes(-sessionMinutes);

        var currentInside = await context.AttendanceRecords
            .Where(a => a.CheckOutTime == null && a.CheckInTime >= cutoffTime)
            .Select(a => a.MemberId)
            .Distinct()
            .CountAsync(cancellationToken);
        
        return new DashboardStatsDto(
            ActiveMembersCount: activeMembers,
            TodayCheckInsCount: todayCheckIns,
            ExpiredSubscriptionsCount: expiredMembers,
            MonthlyRevenue: monthlyRevenue,
            TodayRevenue: todayRevenue,
            MonthlyDropInRevenue:monthlyDropInRevenue,
            CurrentInside :currentInside
        );
    }
}