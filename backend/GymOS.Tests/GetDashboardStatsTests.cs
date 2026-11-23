using GymOS.Application.Features.Dashboard.Queries.GetStats;
using GymOS.Application.Features.Payments.Queries.GetPayments;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;
using GymOS.Tests.Helpers;
using Xunit;

namespace GymOS.Tests;

public class GetDashboardStatsTests
{
    [Fact]
    public async Task Handle_ReturnsDistinctTodayAttendanceAnd7DayAttendanceBreakdown()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var tenant = new GymTenant
        {
            Id = tenantId,
            Name = "Test Gym",
            Subdomain = "testgym",
            DefaultSessionDurationMinutes = 120
        };
        context.Tenants.Add(tenant);

        var member1 = new ApplicationUser
        {
            Id = "mem1",
            TenantId = tenantId,
            FullName = "عضو أول",
            Type = UserType.Member,
            SubscriptionEndDate = DateTime.UtcNow.AddDays(30)
        };
        var member2 = new ApplicationUser
        {
            Id = "mem2",
            TenantId = tenantId,
            FullName = "عضو ثان",
            Type = UserType.Member,
            SubscriptionEndDate = DateTime.UtcNow.AddDays(10)
        };
        context.Users.AddRange(member1, member2);

        var now = DateTime.UtcNow;
        var today = now.Date;

        // Multiple check-ins today for member1, single check-in for member2
        var att1 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member1.Id,
            CheckInTime = today.AddHours(9),
            CheckOutTime = today.AddHours(10)
        };
        var att2 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member1.Id,
            CheckInTime = today.AddHours(14),
            CheckOutTime = today.AddHours(15)
        };
        var att3 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member2.Id,
            CheckInTime = today.AddHours(11),
            CheckOutTime = today.AddHours(12)
        };

        // Attendance 3 days ago for member1 and member2
        var attDayMinus3_1 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member1.Id,
            CheckInTime = today.AddDays(-3).AddHours(10),
            CheckOutTime = today.AddDays(-3).AddHours(11)
        };
        var attDayMinus3_2 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member1.Id, // Same member duplicate on day -3
            CheckInTime = today.AddDays(-3).AddHours(16),
            CheckOutTime = today.AddDays(-3).AddHours(17)
        };
        var attDayMinus3_3 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member2.Id,
            CheckInTime = today.AddDays(-3).AddHours(18),
            CheckOutTime = today.AddDays(-3).AddHours(19)
        };

        context.AttendanceRecords.AddRange(att1, att2, att3, attDayMinus3_1, attDayMinus3_2, attDayMinus3_3);
        await context.SaveChangesAsync();

        var handler = new GetDashboardStatsQueryHandler(context);

        // Act
        var result = await handler.Handle(new GetDashboardStatsQuery(), CancellationToken.None);

        // Assert
        // Today has 3 attendance records, but only 2 unique members
        Assert.Equal(2, result.TodayCheckInsCount);

        // 7 days breakdown
        Assert.NotNull(result.Last7DaysAttendance);
        Assert.Equal(7, result.Last7DaysAttendance.Count);

        // Today's entry is the last one (index 6)
        var todayStat = result.Last7DaysAttendance[6];
        Assert.Equal(DateOnly.FromDateTime(today), todayStat.Date);
        Assert.Equal(2, todayStat.Count);

        // Day -3 is at index 3
        var dayMinus3Stat = result.Last7DaysAttendance[3];
        Assert.Equal(DateOnly.FromDateTime(today.AddDays(-3)), dayMinus3Stat.Date);
        Assert.Equal(2, dayMinus3Stat.Count); // 2 distinct members despite 3 records
    }

    [Fact]
    public async Task Handle_IncludesDropInVisits_InTodayAndMonthlyRevenue()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var tenant = new GymTenant
        {
            Id = tenantId,
            Name = "Revenue Test Gym",
            Subdomain = "revenuetest",
            DefaultSessionDurationMinutes = 120
        };
        context.Tenants.Add(tenant);

        var now = DateTime.UtcNow;
        var today = now.Date;
        var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        // Regular subscription payment today (500)
        var regularPaymentToday = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "member_1",
            Amount = 500m,
            Method = PaymentMethod.Cash,
            PaymentDate = today.AddHours(10),
            IsDropIn = false
        };

        // Drop-in payment today (100)
        var dropInPaymentToday = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "guest_1",
            Amount = 100m,
            Method = PaymentMethod.Cash,
            PaymentDate = today.AddHours(11),
            IsDropIn = true
        };

        // Drop-in payment earlier this month, but before today (if today is 1st of month, place it at startOfMonth hour 1)
        var earlierThisMonth = today > startOfMonth ? today.AddDays(-1).AddHours(12) : startOfMonth.AddMinutes(30);
        var dropInPaymentEarlierThisMonth = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "guest_2",
            Amount = 80m,
            Method = PaymentMethod.InstaPay,
            PaymentDate = earlierThisMonth,
            IsDropIn = true
        };

        // Regular payment earlier this month
        var regularPaymentEarlierThisMonth = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "member_2",
            Amount = 400m,
            Method = PaymentMethod.VodafoneCash,
            PaymentDate = earlierThisMonth,
            IsDropIn = false
        };

        context.PaymentRecords.AddRange(
            regularPaymentToday,
            dropInPaymentToday,
            dropInPaymentEarlierThisMonth,
            regularPaymentEarlierThisMonth
        );
        await context.SaveChangesAsync();

        var handler = new GetDashboardStatsQueryHandler(context);

        // Act
        var result = await handler.Handle(new GetDashboardStatsQuery(), CancellationToken.None);

        // Assert
        // TodayRevenue = 500 (regular) + 100 (drop-in) = 600
        Assert.Equal(600m, result.TodayRevenue);

        // MonthlyRevenue = 500 + 100 + 80 + 400 = 1080
        Assert.Equal(1080m, result.MonthlyRevenue);

        // MonthlyDropInRevenue = 100 + 80 = 180
        Assert.Equal(180m, result.MonthlyDropInRevenue);
    }

    [Fact]
    public async Task Handle_TodayRevenue_EqualsTodayChartBucketAmount_IncludingMidnightAndSingleSession()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var tenant = new GymTenant
        {
            Id = tenantId,
            Name = "Revenue Chart Sync Test Gym",
            Subdomain = "revenuechartsync",
            DefaultSessionDurationMinutes = 120
        };
        context.Tenants.Add(tenant);

        var plan = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId,
            Name = "Monthly Plan",
            Price = 1000m,
            DurationInDays = 30
        };
        context.Plans.Add(plan);

        var member1 = new ApplicationUser
        {
            Id = "member_1",
            UserName = "member1",
            FullName = "Member One",
            TenantId = tenantId
        };
        var guest1 = new ApplicationUser
        {
            Id = "guest_1",
            UserName = "guest1",
            FullName = "Guest One",
            IsGuest = true,
            TenantId = tenantId
        };
        var guest2 = new ApplicationUser
        {
            Id = "guest_2",
            UserName = "guest2",
            FullName = "Guest Two",
            IsGuest = true,
            TenantId = tenantId
        };
        context.Users.AddRange(member1, guest1, guest2);

        var now = DateTime.UtcNow;
        var today = now.Date;
        var tomorrow = today.AddDays(1);
        var yesterday = today.AddDays(-1);

        // 1. Regular payment today at midday (1000 EGP)
        var regularPaymentToday = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "member_1",
            PlanId = plan.Id,
            Amount = 1000m,
            Method = PaymentMethod.Cash,
            PaymentDate = today.AddHours(12),
            IsDropIn = false
        };

        // 2. Single-session (drop-in) payment today (100 EGP) -> Total 1100 so far
        var dropInPaymentToday = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "guest_1",
            Amount = 100m,
            Method = PaymentMethod.InstaPay,
            PaymentDate = today.AddHours(14),
            IsDropIn = true
        };

        // 3. Single-session (drop-in) payment near end-of-day UTC (35 EGP) at 23:59:30 UTC
        // (Edge case: testing day boundary precision)
        var dropInPaymentNearMidnight = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "guest_2",
            Amount = 35m,
            Method = PaymentMethod.VodafoneCash,
            PaymentDate = today.AddHours(23).AddMinutes(59).AddSeconds(30),
            IsDropIn = true
        };

        // 4. Payment yesterday at 23:55 UTC (prior day boundary, should NOT be in TodayRevenue or today's bucket)
        var paymentYesterday = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "member_old",
            Amount = 450m,
            Method = PaymentMethod.Cash,
            PaymentDate = yesterday.AddHours(23).AddMinutes(55),
            IsDropIn = false
        };

        // 5. Payment tomorrow at 00:05 UTC (future boundary, should NOT be in TodayRevenue or today's bucket)
        var paymentTomorrow = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = "member_future",
            Amount = 700m,
            Method = PaymentMethod.Cash,
            PaymentDate = tomorrow.AddMinutes(5),
            IsDropIn = false
        };

        context.PaymentRecords.AddRange(
            regularPaymentToday,
            dropInPaymentToday,
            dropInPaymentNearMidnight,
            paymentYesterday,
            paymentTomorrow
        );
        await context.SaveChangesAsync();

        var dashboardHandler = new GetDashboardStatsQueryHandler(context);
        var paymentsHandler = new GetPaymentsQueryHandler(context);

        // Act
        var stats = await dashboardHandler.Handle(new GetDashboardStatsQuery(), CancellationToken.None);
        var paymentsSummary = await paymentsHandler.Handle(new GetPaymentsQuery("today"), CancellationToken.None);

        // Assert
        Assert.NotNull(stats.Last7DaysRevenue);
        Assert.Equal(7, stats.Last7DaysRevenue.Count);

        var todayChartBucket = stats.Last7DaysRevenue[6];
        Assert.Equal(DateOnly.FromDateTime(today), todayChartBucket.Date);

        // 1000 (regular) + 100 (drop-in) + 35 (drop-in near midnight) = 1135m
        const decimal expectedTodayRevenue = 1135m;
        Assert.Equal(expectedTodayRevenue, stats.TodayRevenue);
        Assert.Equal(expectedTodayRevenue, todayChartBucket.Amount);
        Assert.Equal(stats.TodayRevenue, todayChartBucket.Amount);

        // Also verify details endpoint matches exactly
        Assert.Equal(stats.TodayRevenue, paymentsSummary.TotalAmount);
    }
}
