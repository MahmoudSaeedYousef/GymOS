using GymOS.Application.Features.Attendance.Queries.GetAttendanceHistory;
using GymOS.Domain.Entities;
using GymOS.Tests.Helpers;
using Xunit;

namespace GymOS.Tests;

public class GetAttendanceHistoryTests
{
    [Fact]
    public async Task Handle_ReturnsAttendanceRecords_FilteredByTenantAndDateRange()
    {
        // Arrange
        var tenant1Id = Guid.NewGuid();
        var tenant2Id = Guid.NewGuid();

        var context = TestDbContextFactory.Create(tenant1Id.ToString());

        var member1 = new ApplicationUser
        {
            Id = "user1",
            TenantId = tenant1Id,
            FullName = "أحمد محمود",
            PhoneNumber = "01011111111",
            UserName = "user1"
        };
        var member2 = new ApplicationUser
        {
            Id = "user2",
            TenantId = tenant1Id,
            FullName = "محمد علي",
            PhoneNumber = "01022222222",
            UserName = "user2"
        };
        var otherTenantMember = new ApplicationUser
        {
            Id = "user3",
            TenantId = tenant2Id,
            FullName = "عضو جيم آخر",
            PhoneNumber = "01033333333",
            UserName = "user3"
        };
        context.Users.AddRange(member1, member2, otherTenantMember);

        var now = DateTime.UtcNow;

        var rec1 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenant1Id.ToString(),
            MemberId = member1.Id,
            CheckInTime = now.AddDays(-2),
            CheckOutTime = now.AddDays(-2).AddHours(1)
        };
        var rec2 = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenant1Id.ToString(),
            MemberId = member2.Id,
            CheckInTime = now.AddDays(-10),
            CheckOutTime = null
        };
        var recTooOld = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenant1Id.ToString(),
            MemberId = member1.Id,
            CheckInTime = now.AddDays(-40),
            CheckOutTime = now.AddDays(-40).AddHours(1)
        };
        var recOtherTenant = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            TenantId = tenant2Id.ToString(),
            MemberId = otherTenantMember.Id,
            CheckInTime = now.AddDays(-1),
            CheckOutTime = now.AddDays(-1).AddHours(1)
        };

        context.AttendanceRecords.AddRange(rec1, rec2, recTooOld, recOtherTenant);
        await context.SaveChangesAsync();

        var handler = new GetAttendanceHistoryQueryHandler(context);

        // Act - Default (past 30 days)
        var result = await handler.Handle(new GetAttendanceHistoryQuery(), CancellationToken.None);

        // Assert
        Assert.Equal(2, result.Count);
        Assert.Equal(rec1.Id, result[0].RecordId);
        Assert.Equal(member1.FullName, result[0].FullName);
        Assert.Equal(member1.PhoneNumber, result[0].PhoneNumber);
        Assert.Equal(rec2.Id, result[1].RecordId);
        Assert.Null(result[1].CheckOutTime);

        // Act - Custom date range (past 5 days only)
        var filteredResult = await handler.Handle(
            new GetAttendanceHistoryQuery(now.AddDays(-5), now),
            CancellationToken.None);

        // Assert
        Assert.Single(filteredResult);
        Assert.Equal(rec1.Id, filteredResult[0].RecordId);
    }
}
