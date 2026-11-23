using GymOS.Domain.Entities;
using GymOS.Infrastructure.Services;
using GymOS.Tests.Helpers;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace GymOS.Tests;

public class AutoCheckOutTests
{
    [Fact]
    public async Task ProcessAutoCheckOutAsync_ChecksOutRecordsOlderThanSessionDuration_LeavesOthersUntouched()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var tenant = new GymTenant
        {
            Id = tenantId,
            Name = "Fitness First",
            Subdomain = "fitfirst",
            IsActive = true,
            DefaultSessionDurationMinutes = 180
        };
        context.Tenants.Add(tenant);

        var member = new ApplicationUser
        {
            Id = "user_auto_1",
            TenantId = tenantId,
            FullName = "أحمد مصطفى",
            PhoneNumber = "01099999991",
            UserName = "user_auto_1"
        };
        context.Users.Add(member);

        var now = DateTime.UtcNow;

        // Record 1: Checked in 3.5 hours ago (210 minutes), not checked out -> should auto check out at CheckInTime + 180 min
        var oldCheckInTime = now.AddHours(-3.5);
        var oldRecord = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member.Id,
            CheckInTime = oldCheckInTime,
            CheckOutTime = null
        };

        // Record 2: Checked in 1 hour ago (60 minutes), not checked out -> should remain open (null)
        var recentCheckInTime = now.AddHours(-1);
        var recentRecord = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member.Id,
            CheckInTime = recentCheckInTime,
            CheckOutTime = null
        };

        // Record 3: Already checked out manually -> should be untouched
        var manualCheckInTime = now.AddHours(-4);
        var manualCheckOutTime = now.AddHours(-2);
        var alreadyCheckedOutRecord = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member.Id,
            CheckInTime = manualCheckInTime,
            CheckOutTime = manualCheckOutTime
        };

        context.AttendanceRecords.AddRange(oldRecord, recentRecord, alreadyCheckedOutRecord);
        await context.SaveChangesAsync();

        var service = new AutoCheckOutService(context, NullLogger<AutoCheckOutService>.Instance);

        // Act
        var updatedCount = await service.ProcessAutoCheckOutAsync(now);

        // Assert
        Assert.Equal(1, updatedCount);

        // Reload records
        var updatedOldRecord = await context.AttendanceRecords.FindAsync(oldRecord.Id);
        var updatedRecentRecord = await context.AttendanceRecords.FindAsync(recentRecord.Id);
        var updatedAlreadyRecord = await context.AttendanceRecords.FindAsync(alreadyCheckedOutRecord.Id);

        // Verify old record was checked out at CheckInTime + 180 min
        Assert.NotNull(updatedOldRecord!.CheckOutTime);
        Assert.Equal(oldCheckInTime.AddMinutes(180), updatedOldRecord.CheckOutTime.Value);

        // Verify recent record is still open
        Assert.Null(updatedRecentRecord!.CheckOutTime);

        // Verify already checked out record is untouched
        Assert.Equal(manualCheckOutTime, updatedAlreadyRecord!.CheckOutTime);

        // Verify idempotency: running again updates 0 records
        var secondRunUpdatedCount = await service.ProcessAutoCheckOutAsync(now);
        Assert.Equal(0, secondRunUpdatedCount);
    }

    [Fact]
    public async Task ProcessAutoCheckOutAsync_CustomTenantDuration_UsesConfiguredMinutes()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var context = TestDbContextFactory.Create(tenantId.ToString());

        var tenant = new GymTenant
        {
            Id = tenantId,
            Name = "Express Gym",
            Subdomain = "express",
            IsActive = true,
            DefaultSessionDurationMinutes = 60 // 1 hour custom session
        };
        context.Tenants.Add(tenant);

        var member = new ApplicationUser
        {
            Id = "user_auto_custom",
            TenantId = tenantId,
            FullName = "كريم سامي",
            PhoneNumber = "01099999992",
            UserName = "user_auto_custom"
        };
        context.Users.Add(member);

        var now = DateTime.UtcNow;

        // Checked in 75 minutes ago (> 60 minutes) -> should auto checkout at CheckInTime + 60 min
        var checkIn = now.AddMinutes(-75);
        var record = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId.ToString(),
            MemberId = member.Id,
            CheckInTime = checkIn,
            CheckOutTime = null
        };

        context.AttendanceRecords.Add(record);
        await context.SaveChangesAsync();

        var service = new AutoCheckOutService(context, NullLogger<AutoCheckOutService>.Instance);

        // Act
        var updated = await service.ProcessAutoCheckOutAsync(now);

        // Assert
        Assert.Equal(1, updated);
        var updatedRecord = await context.AttendanceRecords.FindAsync(record.Id);
        Assert.NotNull(updatedRecord!.CheckOutTime);
        Assert.Equal(checkIn.AddMinutes(60), updatedRecord.CheckOutTime.Value);
    }
}
