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
        var tomorrow = today.AddDays(1);
        var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        // بفضل الـ Global Query Filters كل ده متفلتر بالـ TenantId أوتوماتيك!
        
        var activeMembers = await context.Users
            .CountAsync(u => u.SubscriptionEndDate >= now, cancellationToken);
            
        // استبعاد الضيوف من عداد الاشتراكات المنتهية
        var expiredMembers = await context.Users
            .CountAsync(u => !u.IsGuest && u.SubscriptionEndDate < now, cancellationToken);

        // حساب حضور اليوم بالأعضاء الفريدين فقط
        var todayCheckIns = await context.AttendanceRecords
            .Where(a => a.CheckInTime >= today && a.CheckInTime < tomorrow)
            .Select(c => c.MemberId)
            .Distinct()
            .CountAsync(cancellationToken: cancellationToken);
            
        var todayRevenue = await context.PaymentRecords
            .Where(p => p.PaymentDate >= today && p.PaymentDate < tomorrow)
            .SumAsync(p => p.Amount, cancellationToken);

        var monthlyRevenue = await context.PaymentRecords
            .Where(p => p.PaymentDate >= startOfMonth)
            .SumAsync(p => p.Amount, cancellationToken);
        
        var monthlyDropInRevenue = await context.PaymentRecords
            .Where(p => p.PaymentDate >= startOfMonth && p.IsDropIn)
            .SumAsync(p => p.Amount, cancellationToken);
        
        var tenantDuration = await context.Tenants
            .Select(t => (int?)t.DefaultSessionDurationMinutes)
            .FirstOrDefaultAsync(cancellationToken);

        var sessionMinutes = tenantDuration is > 0 ? tenantDuration.Value : 180;

        var cutoffTime = now.AddMinutes(-sessionMinutes);

        var currentInside = await context.AttendanceRecords
            .Where(a => a.CheckOutTime == null && a.CheckInTime >= cutoffTime)
            .Select(a => a.MemberId)
            .Distinct()
            .CountAsync(cancellationToken);

        // 7-day daily attendance breakdown (past 7 calendar days including today)
        var sevenDaysAgo = today.AddDays(-6);
        var attendancePast7Days = await context.AttendanceRecords
            .Where(a => a.CheckInTime >= sevenDaysAgo && a.CheckInTime < tomorrow)
            .Select(a => new { a.MemberId, a.CheckInTime })
            .ToListAsync(cancellationToken);

        var paymentsPast7Days = await context.PaymentRecords
            .Where(p => p.PaymentDate >= sevenDaysAgo && p.PaymentDate < tomorrow)
            .Select(p => new { p.Amount, p.PaymentDate })
            .ToListAsync(cancellationToken);

        var last7DaysAttendance = new List<DailyAttendanceStatDto>();
        var last7DaysRevenue = new List<DailyRevenueStatDto>();
        for (var i = 0; i < 7; i++)
        {
            var targetDay = sevenDaysAgo.AddDays(i);
            var nextDay = targetDay.AddDays(1);
            var dateOnly = DateOnly.FromDateTime(targetDay);

            var count = attendancePast7Days
                .Where(a => a.CheckInTime >= targetDay && a.CheckInTime < nextDay)
                .Select(a => a.MemberId)
                .Distinct()
                .Count();

            var revenue = paymentsPast7Days
                .Where(p => p.PaymentDate >= targetDay && p.PaymentDate < nextDay)
                .Sum(p => p.Amount);

            last7DaysAttendance.Add(new DailyAttendanceStatDto(dateOnly, count));
            last7DaysRevenue.Add(new DailyRevenueStatDto(dateOnly, revenue));
        }
        
        return new DashboardStatsDto(
            ActiveMembersCount: activeMembers,
            TodayCheckInsCount: todayCheckIns,
            ExpiredSubscriptionsCount: expiredMembers,
            MonthlyRevenue: monthlyRevenue,
            TodayRevenue: todayRevenue,
            MonthlyDropInRevenue: monthlyDropInRevenue,
            CurrentInside: currentInside,
            Last7DaysAttendance: last7DaysAttendance,
            Last7DaysRevenue: last7DaysRevenue
        );
    }
}