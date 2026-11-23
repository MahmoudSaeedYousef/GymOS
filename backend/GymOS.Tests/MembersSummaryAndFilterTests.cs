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

    [Fact]
    public async Task GetMembers_WithFilterToday_IncludesBothSubscribedMembersAndGuestSingleSessions()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var today = DateTime.UtcNow.Date;

        // 4 Subscribed members with today's attendance
        var subMembers = Enumerable.Range(1, 4).Select(i => new ApplicationUser
        {
            Id = $"sub_mem_{i}",
            TenantId = tenantId,
            FullName = $"عضو مشترك {i}",
            PhoneNumber = $"0101111000{i}",
            Type = UserType.Member,
            SubscriptionEndDate = today.AddMonths(1),
            IsGuest = false
        }).ToList();

        // 3 Guest / single-session check-ins with today's attendance
        var guestUsers = Enumerable.Range(1, 3).Select(i => new ApplicationUser
        {
            Id = $"guest_session_{i}",
            TenantId = tenantId,
            FullName = i == 1 ? "زائر حصة مفردة" : $"زائر اسم {i}",
            PhoneNumber = $"0109999000{i}",
            Type = UserType.Member,
            SubscriptionEndDate = null,
            IsGuest = true
        }).ToList();

        // 1 Subscribed member with NO attendance today (should NOT appear in today's filter)
        var memberNoAttendance = new ApplicationUser
        {
            Id = "sub_mem_no_attendance",
            TenantId = tenantId,
            FullName = "عضو لم يحضر اليوم",
            PhoneNumber = "01077777777",
            Type = UserType.Member,
            SubscriptionEndDate = today.AddMonths(1),
            IsGuest = false
        };

        context.Users.AddRange(subMembers);
        context.Users.AddRange(guestUsers);
        context.Users.Add(memberNoAttendance);

        // Add today attendance records for 4 subscribed members
        foreach (var m in subMembers)
        {
            context.AttendanceRecords.Add(new AttendanceRecord
            {
                TenantId = tenantId.ToString(),
                MemberId = m.Id,
                CheckInTime = today.AddHours(10)
            });
        }

        // Add today attendance records for 3 guest single-session visitors
        foreach (var g in guestUsers)
        {
            context.AttendanceRecords.Add(new AttendanceRecord
            {
                TenantId = tenantId.ToString(),
                MemberId = g.Id,
                CheckInTime = today.AddHours(11),
                Notes = "حصة مفردة"
            });
        }

        await context.SaveChangesAsync();

        var handler = new GetMembersQueryHandler(context);

        // Act
        var result = await handler.Handle(new GetMembersQuery(Filter: "today", PageSize: 20), CancellationToken.None);

        // Assert
        // Total should be 7 (4 subscribed members + 3 single session guests)
        Assert.Equal(7, result.Items.Count);

        // Verify member without attendance is not included
        Assert.DoesNotContain(result.Items, x => x.Id == memberNoAttendance.Id);

        // Verify guest/single-session mapping
        var guestsInResult = result.Items.Where(x => x.IsSingleSession).ToList();
        Assert.Equal(3, guestsInResult.Count);

        var anonymousGuest = guestsInResult.First(x => x.Id == "guest_session_1");
        Assert.Equal("حصة منفردة", anonymousGuest.FullName);
        Assert.Equal("حصة منفردة", anonymousGuest.ActivePlanName);
        Assert.True(anonymousGuest.IsSingleSession);
        Assert.True(anonymousGuest.IsGuest);
        Assert.Null(anonymousGuest.PhotoUrl);

        var namedGuest = guestsInResult.First(x => x.Id == "guest_session_2");
        Assert.Equal("زائر اسم 2", namedGuest.FullName);
        Assert.Equal("حصة منفردة", namedGuest.ActivePlanName);
        Assert.True(namedGuest.IsSingleSession);
        Assert.True(namedGuest.IsGuest);

        // When query without filter or with active filter, guests must still be excluded
        var activeOnlyResult = await handler.Handle(new GetMembersQuery(Filter: "active", PageSize: 20), CancellationToken.None);
        Assert.All(activeOnlyResult.Items, x => Assert.False(x.IsGuest));
    }
}
