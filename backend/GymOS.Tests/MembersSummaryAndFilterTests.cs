using GymOS.Application.Features.Members.Queries.GetMembers;
using GymOS.Application.Features.Members.Queries.GetMembersSummary;
using GymOS.Domain.Entities;
using GymOS.Tests.Helpers;
using Xunit;

namespace GymOS.Tests;

public class MembersSummaryAndFilterTests
{
    [Fact]
    public async Task GetMembers_WithFilterExpiringSoon_ReturnsOnlyMembersExpiringWithin5Days()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var now = DateTime.UtcNow;
        var today = now.Date;

        var memberExpiringIn2Days = new ApplicationUser
        {
            Id = "mem_exp_2",
            TenantId = tenantId,
            FullName = "عضو ينتهي بعد يومين",
            PhoneNumber = "01011111111",
            Type = UserType.Member,
            SubscriptionEndDate = today.AddDays(2).AddHours(12),
            IsGuest = false
        };

        var memberExpiringIn5Days = new ApplicationUser
        {
            Id = "mem_exp_5",
            TenantId = tenantId,
            FullName = "عضو ينتهي بعد 5 أيام",
            PhoneNumber = "01022222222",
            Type = UserType.Member,
            SubscriptionEndDate = today.AddDays(5),
            IsGuest = false
        };

        var memberExpiringIn10Days = new ApplicationUser
        {
            Id = "mem_active_10",
            TenantId = tenantId,
            FullName = "عضو ينتهي بعد 10 أيام",
            PhoneNumber = "01033333333",
            Type = UserType.Member,
            SubscriptionEndDate = today.AddDays(10),
            IsGuest = false
        };

        var memberExpiredYesterday = new ApplicationUser
        {
            Id = "mem_expired",
            TenantId = tenantId,
            FullName = "عضو منتهي أمس",
            PhoneNumber = "01044444444",
            Type = UserType.Member,
            SubscriptionEndDate = today.AddDays(-1),
            IsGuest = false
        };

        var guestExpiringIn2Days = new ApplicationUser
        {
            Id = "guest_exp_2",
            TenantId = tenantId,
            FullName = "ضيف مؤقت",
            PhoneNumber = "01055555555",
            Type = UserType.Member,
            SubscriptionEndDate = today.AddDays(2),
            IsGuest = true // Should be excluded
        };

        context.Users.AddRange(
            memberExpiringIn2Days,
            memberExpiringIn5Days,
            memberExpiringIn10Days,
            memberExpiredYesterday,
            guestExpiringIn2Days
        );
        await context.SaveChangesAsync();

        var handler = new GetMembersQueryHandler(context);

        // Act - testing both "expiring_soon" and "expiringsoon" case insensitivity
        var resultUnderscore = await handler.Handle(
            new GetMembersQuery(Filter: "expiring_soon", PageSize: 10),
            CancellationToken.None
        );
        var resultUpper = await handler.Handle(
            new GetMembersQuery(Filter: "EXPIRING_SOON", PageSize: 10),
            CancellationToken.None
        );
        var resultWithoutUnderscore = await handler.Handle(
            new GetMembersQuery(Filter: "expiringsoon", PageSize: 10),
            CancellationToken.None
        );

        // Assert
        Assert.Equal(2, resultUnderscore.Items.Count);
        Assert.Contains(resultUnderscore.Items, m => m.Id == memberExpiringIn2Days.Id);
        Assert.Contains(resultUnderscore.Items, m => m.Id == memberExpiringIn5Days.Id);
        Assert.DoesNotContain(resultUnderscore.Items, m => m.Id == memberExpiringIn10Days.Id);
        Assert.DoesNotContain(resultUnderscore.Items, m => m.Id == memberExpiredYesterday.Id);
        Assert.DoesNotContain(resultUnderscore.Items, m => m.Id == guestExpiringIn2Days.Id);

        Assert.Equal(2, resultUpper.Items.Count);
        Assert.Equal(2, resultWithoutUnderscore.Items.Count);
    }

    [Fact]
    public async Task GetMembersSummary_ReturnsCorrectCountsAndPlansShape()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var now = DateTime.UtcNow;
        var today = now.Date;

        var monthlyPlan = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId,
            Name = "باقة شهرية",
            Price = 500m,
            DurationInDays = 30
        };

        var quarterlyPlan = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId,
            Name = "باقة 3 شهور",
            Price = 1200m,
            DurationInDays = 90
        };

        context.Plans.AddRange(monthlyPlan, quarterlyPlan);

        // Member 1: Active, expiring in 3 days (Monthly)
        var m1 = new ApplicationUser
        {
            Id = "m1",
            TenantId = tenantId,
            FullName = "م1",
            IsGuest = false,
            SubscriptionEndDate = today.AddDays(3)
        };
        // Member 2: Active, expiring in 20 days (Monthly)
        var m2 = new ApplicationUser
        {
            Id = "m2",
            TenantId = tenantId,
            FullName = "م2",
            IsGuest = false,
            SubscriptionEndDate = today.AddDays(20)
        };
        // Member 3: Active, expiring in 40 days (Quarterly)
        var m3 = new ApplicationUser
        {
            Id = "m3",
            TenantId = tenantId,
            FullName = "م3",
            IsGuest = false,
            SubscriptionEndDate = today.AddDays(40)
        };
        // Member 4: Expired 5 days ago (Quarterly)
        var m4 = new ApplicationUser
        {
            Id = "m4",
            TenantId = tenantId,
            FullName = "م4",
            IsGuest = false,
            SubscriptionEndDate = today.AddDays(-5)
        };
        // Member 5: Guest (should be ignored completely)
        var guest = new ApplicationUser
        {
            Id = "guest1",
            TenantId = tenantId,
            FullName = "ضيف",
            IsGuest = true,
            SubscriptionEndDate = today.AddDays(2)
        };

        context.Users.AddRange(m1, m2, m3, m4, guest);

        // Subscriptions
        var dateOnlyToday = DateOnly.FromDateTime(today);
        context.Subscriptions.AddRange(
            new Subscription
            {
                Id = Guid.NewGuid(),
                TenantId = tenantId,
                MemberId = m1.Id,
                PlanId = monthlyPlan.Id,
                StartDate = dateOnlyToday.AddDays(-27),
                EndDate = dateOnlyToday.AddDays(3)
            },
            new Subscription
            {
                Id = Guid.NewGuid(),
                TenantId = tenantId,
                MemberId = m2.Id,
                PlanId = monthlyPlan.Id,
                StartDate = dateOnlyToday.AddDays(-10),
                EndDate = dateOnlyToday.AddDays(20)
            },
            new Subscription
            {
                Id = Guid.NewGuid(),
                TenantId = tenantId,
                MemberId = m3.Id,
                PlanId = quarterlyPlan.Id,
                StartDate = dateOnlyToday.AddDays(-50),
                EndDate = dateOnlyToday.AddDays(40)
            },
            new Subscription
            {
                Id = Guid.NewGuid(),
                TenantId = tenantId,
                MemberId = m4.Id,
                PlanId = quarterlyPlan.Id,
                StartDate = dateOnlyToday.AddDays(-95),
                EndDate = dateOnlyToday.AddDays(-5)
            }
        );

        await context.SaveChangesAsync();

        var handler = new GetMembersSummaryQueryHandler(context);

        // Act
        var summary = await handler.Handle(new GetMembersSummaryQuery(), CancellationToken.None);

        // Assert
        // Total non-guest members = 4
        Assert.Equal(4, summary.Total);
        // Active = m1, m2, m3 = 3
        Assert.Equal(3, summary.Active);
        // Expired = m4 = 1
        Assert.Equal(1, summary.Expired);
        // Expiring Soon = m1 (expires in 3 days) = 1
        Assert.Equal(1, summary.ExpiringSoon);

        // Plans grouped count:
        // Monthly: 2 members (m1, m2)
        // Quarterly: 2 members (m3, m4)
        Assert.Equal(2, summary.Plans.Count);
        Assert.All(summary.Plans, p => Assert.Equal(2, p.Count));
    }
}
