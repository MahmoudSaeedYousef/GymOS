using GymOS.Domain.Entities;
using GymOS.Domain.Enums;
using GymOS.Infrastructure.Data;
using GymOS.Tests.Helpers;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace GymOS.Tests;

public class GymHistorySeederTests
{
    [Fact]
    public async Task Seed30DayHistoryAsync_PreservesExistingMembersAndPlans_AndGeneratesConsistentRecords()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(gymId.ToString());

        var gym = new GymTenant
        {
            Id = gymId,
            Name = "Champion Fitness Gym",
            Subdomain = "champion",
            DefaultSessionDurationMinutes = 120
        };
        context.Tenants.Add(gym);

        var plan1 = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = gymId,
            Name = "خطة شهرية",
            Price = 600m,
            DurationInDays = 30,
            Kind = PlanKind.Duration,
            IsActive = true
        };
        var plan2 = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = gymId,
            Name = "خطة 3 شهور",
            Price = 1500m,
            DurationInDays = 90,
            Kind = PlanKind.Duration,
            IsActive = true
        };
        var dropInPlan = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = gymId,
            Name = "حصة مفردة",
            Price = 70m,
            DurationInDays = 1,
            Kind = PlanKind.VisitPack,
            VisitsIncluded = 1,
            IsActive = true
        };
        context.Plans.AddRange(plan1, plan2, dropInPlan);

        // Add 20 existing members
        var existingMembers = new List<ApplicationUser>();
        for (var i = 1; i <= 20; i++)
        {
            var member = new ApplicationUser
            {
                Id = $"member_{i}",
                TenantId = gymId,
                Type = UserType.Member,
                FullName = $"مشترك تجريبي {i}",
                PhoneNumber = $"010000000{i:D2}",
                UserName = $"member{i}",
                NormalizedUserName = $"MEMBER{i}",
                IsGuest = false
            };
            existingMembers.Add(member);
        }
        context.Users.AddRange(existingMembers);

        // Add some old test transactions that should be cleaned
        var oldSub = new Subscription
        {
            Id = Guid.NewGuid(),
            TenantId = gymId,
            MemberId = "member_1",
            PlanId = plan1.Id,
            StartDate = new DateOnly(2025, 1, 1),
            EndDate = new DateOnly(2025, 2, 1)
        };
        var oldPayment = new PaymentRecord
        {
            Id = Guid.NewGuid(),
            TenantId = gymId.ToString(),
            MemberId = "member_1",
            PlanId = plan1.Id,
            Amount = 100m,
            PaymentDate = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        };
        var oldAttendance = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = gymId.ToString(),
            MemberId = "member_1",
            CheckInTime = new DateTime(2025, 1, 1, 10, 0, 0, DateTimeKind.Utc)
        };
        context.Subscriptions.Add(oldSub);
        context.PaymentRecords.Add(oldPayment);
        context.AttendanceRecords.Add(oldAttendance);
        await context.SaveChangesAsync();

        var seeder = new GymHistorySeeder(context);
        var anchorTime = new DateTime(2026, 11, 21, 12, 0, 0, DateTimeKind.Utc);

        // Act
        var result = await seeder.Seed30DayHistoryAsync(gymId, anchorTime);

        // Assert
        Assert.True(result.Success);
        Assert.Equal(gymId, result.GymId);

        // 1. Verify Plans and Existing Members were NOT deleted
        var plansInDb = await context.Plans.IgnoreQueryFilters().Where(p => p.TenantId == gymId).ToListAsync();
        Assert.Equal(3, plansInDb.Count);

        var originalMembersInDb = await context.Users.IgnoreQueryFilters()
            .Where(u => u.TenantId == gymId && existingMembers.Select(m => m.Id).Contains(u.Id))
            .ToListAsync();
        Assert.Equal(20, originalMembersInDb.Count);

        // Check if extra members were added to reach 60
        var allMembers = await context.Users.IgnoreQueryFilters().Where(u => u.TenantId == gymId && u.Type == UserType.Member && !u.IsGuest).ToListAsync();
        var totalMembers = allMembers.Count;
        Assert.Equal(60, totalMembers);
        Assert.Equal(result.MembersCount, totalMembers);

        // Verify realistic gender distribution among newly added members
        var newlyAddedMembers = allMembers.Where(u => !existingMembers.Select(m => m.Id).Contains(u.Id)).ToList();
        Assert.Equal(40, newlyAddedMembers.Count);
        var maleCount = newlyAddedMembers.Count(u => u.Gender == Gender.Male);
        var femaleCount = newlyAddedMembers.Count(u => u.Gender == Gender.Female);
        Assert.Equal(20, maleCount);
        Assert.Equal(20, femaleCount);

        // 2. Old transactions were cleaned
        Assert.DoesNotContain(context.Subscriptions.IgnoreQueryFilters(), s => s.Id == oldSub.Id);
        Assert.DoesNotContain(context.PaymentRecords.IgnoreQueryFilters(), p => p.Id == oldPayment.Id);
        Assert.DoesNotContain(context.AttendanceRecords.IgnoreQueryFilters(), a => a.Id == oldAttendance.Id);

        // 3. Subscriptions distribution
        var subs = await context.Subscriptions.IgnoreQueryFilters().Where(s => s.TenantId == gymId).ToListAsync();
        Assert.Equal(totalMembers, subs.Count);
        Assert.Equal(result.SubscriptionsCreated, subs.Count);
        Assert.True(result.ActiveSubscriptionsCount > 0);
        Assert.True(result.ExpiringSoonSubscriptionsCount > 0);
        Assert.True(result.ExpiredSubscriptionsCount > 0);

        // 4. Payments
        var payments = await context.PaymentRecords.IgnoreQueryFilters().Where(p => p.TenantId == gymId.ToString()).ToListAsync();
        Assert.Equal(result.PaymentsCreated, payments.Count);
        Assert.Equal(12, result.DropInPaymentsCreated); // 10 past + 2 today
        Assert.Equal(totalMembers + 12, payments.Count);

        // 5. Attendance
        var attendances = await context.AttendanceRecords.IgnoreQueryFilters().Where(a => a.TenantId == gymId.ToString()).ToListAsync();
        Assert.Equal(result.AttendanceRecordsCreated, attendances.Count);
        Assert.InRange(attendances.Count, 180, 320); // 30 days realistic range
        Assert.Equal(9, result.TodayAttendanceRecordsCreated);
        Assert.Equal(3, result.CurrentlyInsideCount);

        // Verify currently inside members have CheckOutTime == null
        var currentlyInside = attendances.Where(a => a.CheckOutTime == null).ToList();
        Assert.Equal(3, currentlyInside.Count);
        foreach (var activeRecord in currentlyInside)
        {
            Assert.True(activeRecord.CheckInTime >= anchorTime.AddMinutes(-90));
            Assert.True(activeRecord.CheckInTime <= anchorTime);
        }
    }
}
