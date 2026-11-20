using GymOS.Application.Features.Attendance.Commands.CheckIn;
using GymOS.Application.Features.Attendance.Commands.CheckOut;
using GymOS.Application.Features.Members.Commands.CreateMember;
using GymOS.Application.Features.Payments.Commands.RenewSubscription;
using GymOS.Application.Features.Subscriptions.Commands.SubscribeMember;
using GymOS.Application.Features.Visits.Commands.RecordDropInVisit;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;
using GymOS.Infrastructure.Data;
using GymOS.Tests.Helpers;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Xunit;

namespace GymOS.Tests;

public class ClientGeneratedIdTests
{
    private (GymDbContext DbContext, UserManager<ApplicationUser> UserManager, TestTenantService TenantService) SetupEnvironment(Guid gymId)
    {
        var services = new ServiceCollection();
        services.AddLogging(b => b.AddConsole());

        var db = TestDbContextFactory.Create(gymId.ToString());
        var tenantService = new TestTenantService(gymId.ToString());

        services.AddSingleton(db);
        services.AddIdentity<ApplicationUser, IdentityRole>()
            .AddEntityFrameworkStores<GymDbContext>()
            .AddDefaultTokenProviders();

        var sp = services.BuildServiceProvider();
        var userManager = sp.GetRequiredService<UserManager<ApplicationUser>>();

        return (db, userManager, tenantService);
    }

    [Fact]
    public async Task CreateMember_WithClientId_PersistsExactId()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var (context, userManager, tenantService) = SetupEnvironment(gymId);

        var customClientId = Guid.NewGuid();
        var clientTimestamp = DateTime.UtcNow.AddMinutes(-30);

        var handler = new CreateMemberCommandHandler(userManager, context, tenantService);
        var command = new CreateMemberCommand(
            FullName: "Ahmed Offline",
            PhoneNumber: "01099998888",
            PlanId: null,
            StartDate: null,
            ClientId: customClientId,
            OccurredAtUtc: clientTimestamp
        );

        // Act
        var createdMemberId = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.Equal(customClientId.ToString(), createdMemberId);

        var memberInDb = await context.Users.IgnoreQueryFilters().FirstOrDefaultAsync(u => u.Id == customClientId.ToString());
        Assert.NotNull(memberInDb);
        Assert.Equal("Ahmed Offline", memberInDb.FullName);
        Assert.Equal("01099998888", memberInDb.PhoneNumber);
        Assert.Equal(gymId, memberInDb.TenantId);
    }

    [Fact]
    public async Task CheckIn_WithClientIdAndOccurredAtUtc_PersistsExactIdAndTimestamp()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var (context, userManager, _) = SetupEnvironment(gymId);

        var member = new ApplicationUser
        {
            Id = Guid.NewGuid().ToString(),
            UserName = "checkin_member",
            FullName = "Member Checkin",
            TenantId = gymId,
            SubscriptionEndDate = DateTime.UtcNow.AddDays(15)
        };
        await userManager.CreateAsync(member, "Password@123");

        var customAttendanceId = Guid.NewGuid();
        var offlineCheckInTime = DateTime.UtcNow.AddHours(-2);

        var handler = new CheckInCommandHandler(context);
        var command = new CheckInCommand(
            MemberId: member.Id,
            ClientId: customAttendanceId,
            OccurredAtUtc: offlineCheckInTime,
            Notes: "Offline CheckIn"
        );

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.Equal(customAttendanceId, result.AttendanceId);

        var recordInDb = await context.AttendanceRecords
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(a => a.Id == customAttendanceId);

        Assert.NotNull(recordInDb);
        Assert.Equal(customAttendanceId, recordInDb.Id);
        Assert.Equal(member.Id, recordInDb.MemberId);
        Assert.Equal(offlineCheckInTime, recordInDb.CheckInTime);
        Assert.Equal("Offline CheckIn", recordInDb.Notes);
    }

    [Fact]
    public async Task CheckOut_WithOccurredAtUtc_PersistsRealTimestamp()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var (context, _, _) = SetupEnvironment(gymId);

        var recordId = Guid.NewGuid();
        var checkInTime = DateTime.UtcNow.AddHours(-3);
        var checkOutTime = DateTime.UtcNow.AddHours(-1);

        var record = new AttendanceRecord
        {
            Id = recordId,
            TenantId = gymId.ToString(),
            MemberId = Guid.NewGuid().ToString(),
            CheckInTime = checkInTime
        };
        context.AttendanceRecords.Add(record);
        await context.SaveChangesAsync();

        var handler = new CheckOutCommandHandler(context);
        var command = new CheckOutCommand(recordId, OccurredAtUtc: checkOutTime);

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result.IsSuccess);

        var updatedRecord = await context.AttendanceRecords.IgnoreQueryFilters().FirstOrDefaultAsync(a => a.Id == recordId);
        Assert.NotNull(updatedRecord);
        Assert.Equal(checkOutTime, updatedRecord.CheckOutTime);
    }

    [Fact]
    public async Task RecordDropIn_WithClientIdsAndOccurredAtUtc_PersistsExactIdsAndTimestamp()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var (context, _, tenantService) = SetupEnvironment(gymId);

        var customPaymentId = Guid.NewGuid();
        var customAttendanceId = Guid.NewGuid();
        var offlineTime = DateTime.UtcNow.AddHours(-4);
        var opId = Guid.NewGuid();

        var handler = new RecordDropInVisitCommandHandler(context, tenantService);
        var command = new RecordDropInVisitCommand(
            OperationId: opId,
            PlanId: null,
            CustomAmount: 150m,
            PaymentMethod: "Cash",
            GuestName: "DropIn Guest",
            GuestPhone: "01011223344",
            Notes: "Offline DropIn",
            Method: PaymentMethod.Cash,
            Id: customPaymentId,
            AttendanceId: customAttendanceId,
            OccurredAtUtc: offlineTime
        );

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result.Succeeded);
        Assert.Equal(customPaymentId, result.PaymentId);
        Assert.Equal(customAttendanceId, result.AttendanceId);

        var paymentInDb = await context.PaymentRecords.IgnoreQueryFilters().FirstOrDefaultAsync(p => p.Id == customPaymentId);
        Assert.NotNull(paymentInDb);
        Assert.Equal(offlineTime, paymentInDb.PaymentDate);
        Assert.Equal(150m, paymentInDb.Amount);

        var attendanceInDb = await context.AttendanceRecords.IgnoreQueryFilters().FirstOrDefaultAsync(a => a.Id == customAttendanceId);
        Assert.NotNull(attendanceInDb);
        Assert.Equal(offlineTime, attendanceInDb.CheckInTime);
    }

    [Fact]
    public async Task RenewSubscription_WithClientIdAndOccurredAtUtc_PersistsExactIdAndTimestamp()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var (context, userManager, _) = SetupEnvironment(gymId);

        var member = new ApplicationUser
        {
            Id = Guid.NewGuid().ToString(),
            UserName = "renew_member",
            FullName = "Member Renew",
            TenantId = gymId,
            SubscriptionEndDate = DateTime.UtcNow.AddDays(5)
        };
        await userManager.CreateAsync(member, "Password@123");

        var plan = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = gymId,
            Name = "Monthly Gold",
            Price = 500m,
            DurationInDays = 30,
            Kind = PlanKind.Duration,
            IsActive = true
        };
        context.Plans.Add(plan);
        await context.SaveChangesAsync();

        var customSubscriptionId = Guid.NewGuid();
        var customPaymentId = Guid.NewGuid();
        var offlineTime = DateTime.UtcNow.AddHours(-1);

        var handler = new RenewSubscriptionCommandHandler(context);
        var command = new RenewSubscriptionCommand(
            MemberId: member.Id,
            PlanId: plan.Id,
            PaymentMethod: PaymentMethod.Cash,
            AmountPaid: 500m,
            Notes: "Offline Renew",
            SubscriptionId: customSubscriptionId,
            PaymentId: customPaymentId,
            OccurredAtUtc: offlineTime
        );

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result.IsSuccess);

        var subInDb = await context.Subscriptions.IgnoreQueryFilters().FirstOrDefaultAsync(s => s.Id == customSubscriptionId);
        Assert.NotNull(subInDb);
        Assert.Equal(customSubscriptionId, subInDb.Id);

        var payInDb = await context.PaymentRecords.IgnoreQueryFilters().FirstOrDefaultAsync(p => p.Id == customPaymentId);
        Assert.NotNull(payInDb);
        Assert.Equal(customPaymentId, payInDb.Id);
        Assert.Equal(offlineTime, payInDb.PaymentDate);
    }

    [Fact]
    public async Task SubscribeMember_WithClientId_PersistsExactId()
    {
        // Arrange
        var gymId = Guid.NewGuid();
        var (context, userManager, tenantService) = SetupEnvironment(gymId);

        var member = new ApplicationUser
        {
            Id = Guid.NewGuid().ToString(),
            UserName = "sub_member",
            FullName = "Member Sub",
            TenantId = gymId
        };
        await userManager.CreateAsync(member, "Password@123");

        var plan = new Plan
        {
            Id = Guid.NewGuid(),
            TenantId = gymId,
            Name = "Quarterly",
            Price = 1200m,
            DurationInDays = 90,
            Kind = PlanKind.Duration,
            IsActive = true
        };
        context.Plans.Add(plan);
        await context.SaveChangesAsync();

        var customSubId = Guid.NewGuid();
        var handler = new SubscribeMemberCommandHandler(context, tenantService);
        var command = new SubscribeMemberCommand(
            MemberId: member.Id,
            PlanId: plan.Id,
            StartDate: DateOnly.FromDateTime(DateTime.UtcNow),
            ClientId: customSubId
        );

        // Act
        var subId = await handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.Equal(customSubId, subId);

        var subInDb = await context.Subscriptions.IgnoreQueryFilters().FirstOrDefaultAsync(s => s.Id == customSubId);
        Assert.NotNull(subInDb);
        Assert.Equal(customSubId, subInDb.Id);
    }
}
