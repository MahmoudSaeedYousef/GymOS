using GymOS.Application.Features.Dev;
using GymOS.Domain.Entities;
using GymOS.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Infrastructure.Data;

public class GymHistorySeeder(GymDbContext dbContext) : IGymHistorySeeder
{
    public async Task<PopulateHistoryResult> Seed30DayHistoryAsync(
        Guid? gymId = null,
        DateTime? anchorTimeUtc = null,
        CancellationToken cancellationToken = default)
    {
        var now = anchorTimeUtc ?? DateTime.UtcNow;
        var today = DateOnly.FromDateTime(now);

        // 1. Resolve Target Gym
        GymTenant? targetGym = null;
        if (gymId.HasValue && gymId.Value != Guid.Empty)
        {
            targetGym = await dbContext.Tenants
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(t => t.Id == gymId.Value, cancellationToken);

            if (targetGym == null)
            {
                return new PopulateHistoryResult(
                    Success: false,
                    Message: $"Gym tenant with Id '{gymId.Value}' was not found.",
                    GymId: gymId.Value,
                    MembersCount: 0,
                    NewMembersAdded: 0,
                    SubscriptionsCreated: 0,
                    ActiveSubscriptionsCount: 0,
                    ExpiringSoonSubscriptionsCount: 0,
                    ExpiredSubscriptionsCount: 0,
                    PaymentsCreated: 0,
                    DropInPaymentsCreated: 0,
                    TotalPaymentsRevenue: 0,
                    AttendanceRecordsCreated: 0,
                    TodayAttendanceRecordsCreated: 0,
                    CurrentlyInsideCount: 0
                );
            }
        }
        else
        {
            targetGym = await dbContext.Tenants
                .IgnoreQueryFilters()
                .OrderBy(t => t.CreatedAtUtc)
                .FirstOrDefaultAsync(cancellationToken);

            if (targetGym == null)
            {
                return new PopulateHistoryResult(
                    Success: false,
                    Message: "No Gym tenant found in the database.",
                    GymId: Guid.Empty,
                    MembersCount: 0,
                    NewMembersAdded: 0,
                    SubscriptionsCreated: 0,
                    ActiveSubscriptionsCount: 0,
                    ExpiringSoonSubscriptionsCount: 0,
                    ExpiredSubscriptionsCount: 0,
                    PaymentsCreated: 0,
                    DropInPaymentsCreated: 0,
                    TotalPaymentsRevenue: 0,
                    AttendanceRecordsCreated: 0,
                    TodayAttendanceRecordsCreated: 0,
                    CurrentlyInsideCount: 0
                );
            }
        }

        var targetGymId = targetGym.Id;
        var targetGymIdString = targetGymId.ToString();

        // 2. Query Existing Plans (Do NOT delete or overwrite)
        var existingPlans = await dbContext.Plans
            .IgnoreQueryFilters()
            .Where(p => p.TenantId == targetGymId && !p.IsDeleted)
            .ToListAsync(cancellationToken);

        if (existingPlans.Count == 0)
        {
            // If the gym has no plans yet, create standard defaults so we can seed history
            var monthlyPlan = new Plan
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymId,
                Name = "اشتراك شهر - Monthly Plan",
                Price = 500m,
                DurationInDays = 30,
                Kind = PlanKind.Duration,
                IsActive = true,
                CreatedAtUtc = now.AddDays(-35)
            };
            var quarterlyPlan = new Plan
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymId,
                Name = "اشتراك 3 شهور - 3 Months Plan",
                Price = 1200m,
                DurationInDays = 90,
                Kind = PlanKind.Duration,
                IsActive = true,
                CreatedAtUtc = now.AddDays(-35)
            };
            var dropInPlan = new Plan
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymId,
                Name = "حصة مفردة - Drop-in Visit",
                Price = 60m,
                DurationInDays = 1,
                Kind = PlanKind.VisitPack,
                VisitsIncluded = 1,
                IsActive = true,
                CreatedAtUtc = now.AddDays(-35)
            };

            dbContext.Plans.AddRange(monthlyPlan, quarterlyPlan, dropInPlan);
            await dbContext.SaveChangesAsync(cancellationToken);
            existingPlans.AddRange([monthlyPlan, quarterlyPlan, dropInPlan]);
        }

        var durationPlans = existingPlans.Where(p => p.Kind == PlanKind.Duration).ToList();
        if (durationPlans.Count == 0)
        {
            durationPlans = existingPlans; // fallback if only visit packs exist
        }

        // 3. Query Existing Members (Do NOT delete or overwrite)
        var members = await dbContext.Users
            .IgnoreQueryFilters()
            .Where(u => u.TenantId == targetGymId && u.Type == UserType.Member && !u.IsGuest)
            .OrderBy(u => u.Id)
            .ToListAsync(cancellationToken);

        var newMembersAdded = 0;
        if (members.Count < 25)
        {
            var extraEgyptianNames = new[]
            {
                ("أحمد حسن مصطفى", "01091234501"),
                ("محمد علي إبراهيم", "01182345602"),
                ("محمود طارق الشناوي", "01273456703"),
                ("كريم سمير عبد العزيز", "01064567804"),
                ("عمر شريف الدسوقي", "01555678905"),
                ("يوسف علاء البدري", "01146789006"),
                ("سارة مصطفى كمال", "01237890107"),
                ("نور الدين حسام فهمي", "01028901208"),
                ("مريم هشام فاروق", "01519012309"),
                ("خالد وليد الجندي", "01100123410")
            };

            var toAddCount = Math.Min(25 - members.Count, extraEgyptianNames.Length);
            for (var i = 0; i < toAddCount; i++)
            {
                var (name, phone) = extraEgyptianNames[i];
                var existingPhone = await dbContext.Users
                    .IgnoreQueryFilters()
                    .AnyAsync(u => u.TenantId == targetGymId && u.PhoneNumber == phone, cancellationToken);

                if (!existingPhone)
                {
                    var suffix = Guid.NewGuid().ToString("N")[..6];
                    var newMember = new ApplicationUser
                    {
                        Id = Guid.CreateVersion7().ToString(),
                        TenantId = targetGymId,
                        Type = UserType.Member,
                        FullName = name,
                        PhoneNumber = phone,
                        UserName = $"{phone}_{suffix}",
                        NormalizedUserName = $"{phone}_{suffix}".ToUpperInvariant(),
                        IsGuest = false
                    };
                    dbContext.Users.Add(newMember);
                    members.Add(newMember);
                    newMembersAdded++;
                }
            }

            if (newMembersAdded > 0)
            {
                await dbContext.SaveChangesAsync(cancellationToken);
            }
        }

        // 4. Clean Reset of Old Test Transactions ONLY for target gym
        // (AttendanceRecords, PaymentRecords, Subscriptions)
        var oldAttendance = await dbContext.AttendanceRecords
            .IgnoreQueryFilters()
            .Where(a => a.TenantId == targetGymIdString)
            .ToListAsync(cancellationToken);
        dbContext.AttendanceRecords.RemoveRange(oldAttendance);

        var oldPayments = await dbContext.PaymentRecords
            .IgnoreQueryFilters()
            .Where(p => p.TenantId == targetGymIdString)
            .ToListAsync(cancellationToken);
        dbContext.PaymentRecords.RemoveRange(oldPayments);

        var oldSubscriptions = await dbContext.Subscriptions
            .IgnoreQueryFilters()
            .Where(s => s.TenantId == targetGymId)
            .ToListAsync(cancellationToken);
        dbContext.Subscriptions.RemoveRange(oldSubscriptions);

        await dbContext.SaveChangesAsync(cancellationToken);

        // 5. Distribute Subscriptions Realistically Across Existing Members
        // Target: ~65% Active, ~15% Expiring Soon (1-3 days), ~20% Expired (1-10 days ago)
        var totalMembers = members.Count;
        var expiredCount = (int)Math.Round(totalMembers * 0.20);
        var expiringSoonCount = (int)Math.Round(totalMembers * 0.15);
        if (expiredCount < 1 && totalMembers >= 3) expiredCount = 1;
        if (expiringSoonCount < 1 && totalMembers >= 4) expiringSoonCount = 1;
        var activeCount = totalMembers - expiredCount - expiringSoonCount;

        var subscriptions = new List<Subscription>();
        var payments = new List<PaymentRecord>();

        var random = new Random(42); // deterministic seed for stability
        var paymentMethods = new[] { PaymentMethod.Cash, PaymentMethod.InstaPay, PaymentMethod.VodafoneCash };

        for (var i = 0; i < totalMembers; i++)
        {
            var member = members[i];
            var plan = durationPlans[i % durationPlans.Count];
            var planDuration = plan.DurationInDays > 0 ? plan.DurationInDays : 30;

            DateOnly subStartDate;
            DateOnly subEndDate;

            if (i < expiredCount)
            {
                // Expired 1-10 days ago
                var daysExpired = 1 + (i % 10);
                subEndDate = today.AddDays(-daysExpired);
                subStartDate = subEndDate.AddDays(-planDuration);
            }
            else if (i < expiredCount + expiringSoonCount)
            {
                // Expiring soon: 1-3 days ahead
                var daysLeft = 1 + ((i - expiredCount) % 3);
                subEndDate = today.AddDays(daysLeft);
                subStartDate = subEndDate.AddDays(-planDuration);
            }
            else
            {
                // Active: started 3-25 days ago, valid for 6-150 days
                var startAgo = 3 + (random.Next(23)); // 3 to 25
                subStartDate = today.AddDays(-startAgo);
                subEndDate = subStartDate.AddDays(planDuration);
                if (subEndDate <= today)
                {
                    subEndDate = today.AddDays(15);
                }
            }

            var subscription = new Subscription
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymId,
                MemberId = member.Id,
                PlanId = plan.Id,
                StartDate = subStartDate,
                EndDate = subEndDate
            };
            subscription.Activate();
            subscriptions.Add(subscription);

            // Update user's denormalized subscription end date
            member.SubscriptionEndDate = subEndDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
            member.IsGuest = false;

            // Matching payment record dated at subscription StartDate
            var method = paymentMethods[random.Next(paymentMethods.Length)];
            var paymentTime = subStartDate.ToDateTime(new TimeOnly(10 + random.Next(11), random.Next(60)), DateTimeKind.Utc);
            var payment = new PaymentRecord
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymIdString,
                MemberId = member.Id,
                PlanId = plan.Id,
                Amount = plan.Price,
                Method = method,
                PaymentDate = paymentTime,
                IsDropIn = false,
                Notes = method == PaymentMethod.InstaPay
                    ? $"InstaPay Ref #{random.Next(100000, 999999)}"
                    : (method == PaymentMethod.VodafoneCash ? $"VF Cash: 010{random.Next(10000000, 99999999)}" : "دفع نقدي بالاستقبال")
            };
            payments.Add(payment);
        }

        // 6. Generate ~12 Drop-in Payments Spread Across Past 30 Days (including 2 today)
        var dropInPlanObj = existingPlans.FirstOrDefault(p => p.Kind == PlanKind.VisitPack && p.VisitsIncluded == 1)
                            ?? existingPlans.FirstOrDefault(p => p.Kind == PlanKind.VisitPack)
                            ?? existingPlans.First();
        var dropInPrice = dropInPlanObj.Price > 0 ? dropInPlanObj.Price : 60m;

        var dropInPaymentsCount = 0;
        // 10 drop-ins on previous days
        for (var d = 1; d <= 10; d++)
        {
            var dayOffset = (d * 3) - random.Next(2);
            if (dayOffset > 29) dayOffset = 29;
            if (dayOffset < 1) dayOffset = 1;

            var dropInMember = members[(d + 5) % members.Count];
            var dropInDate = now.AddDays(-dayOffset).Date
                .AddHours(11 + random.Next(9))
                .AddMinutes(random.Next(60));

            var method = paymentMethods[random.Next(paymentMethods.Length)];
            var dropInPayment = new PaymentRecord
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymIdString,
                MemberId = dropInMember.Id,
                PlanId = dropInPlanObj.Id,
                Amount = dropInPrice,
                Method = method,
                PaymentDate = DateTime.SpecifyKind(dropInDate, DateTimeKind.Utc),
                IsDropIn = true,
                Notes = "حصة مفردة - Drop-in Visit"
            };
            payments.Add(dropInPayment);
            dropInPaymentsCount++;
        }

        // 2 drop-ins TODAY
        for (var t = 0; t < 2; t++)
        {
            var dropInMember = members[(t + 2) % members.Count];
            var todayDropInTime = now.Date
                .AddHours(9 + (t * 2))
                .AddMinutes(random.Next(45));

            var method = paymentMethods[t % paymentMethods.Length];
            var dropInPayment = new PaymentRecord
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymIdString,
                MemberId = dropInMember.Id,
                PlanId = dropInPlanObj.Id,
                Amount = dropInPrice,
                Method = method,
                PaymentDate = DateTime.SpecifyKind(todayDropInTime, DateTimeKind.Utc),
                IsDropIn = true,
                Notes = "حصة مفردة اليوم - Today Drop-in"
            };
            payments.Add(dropInPayment);
            dropInPaymentsCount++;
        }

        // 7. Generate Realistic 30-Day & 7-Day Attendance Records (~180–220)
        // Heavier on Saturday (DayOfWeek.Saturday), Monday (Monday), Wednesday (Wednesday); lighter on Friday (Friday).
        // For today: 7-10 check-ins, with exactly 3 members currently inside (CheckOutTime = null, checked in within 15-90 min).
        var attendances = new List<AttendanceRecord>();

        // Previous 29 days attendance:
        for (var dayAgo = 29; dayAgo >= 1; dayAgo--)
        {
            var targetDay = now.AddDays(-dayAgo).Date;
            var dayOfWeek = targetDay.DayOfWeek;

            int targetDailyCount = dayOfWeek switch
            {
                DayOfWeek.Saturday => random.Next(8, 11),
                DayOfWeek.Monday => random.Next(8, 11),
                DayOfWeek.Wednesday => random.Next(8, 11),
                DayOfWeek.Friday => random.Next(2, 5),   // Friday lighter
                _ => random.Next(5, 8)                   // Sun, Tue, Thu moderate
            };

            var shuffledMembers = members.OrderBy(_ => random.Next()).Take(targetDailyCount).ToList();
            foreach (var m in shuffledMembers)
            {
                var hour = random.Next(0, 10) < 3
                    ? random.Next(8, 12)   // 30% morning
                    : random.Next(16, 22); // 70% evening

                var checkIn = targetDay.AddHours(hour).AddMinutes(random.Next(60));
                var durationMinutes = random.Next(60, 95);
                var checkOut = checkIn.AddMinutes(durationMinutes);

                attendances.Add(new AttendanceRecord
                {
                    Id = Guid.CreateVersion7(),
                    TenantId = targetGymIdString,
                    MemberId = m.Id,
                    CheckInTime = DateTime.SpecifyKind(checkIn, DateTimeKind.Utc),
                    CheckOutTime = DateTime.SpecifyKind(checkOut, DateTimeKind.Utc),
                    Notes = "تسجيل حضور اعتيادي"
                });
            }
        }

        // TODAY's Attendance (7 to 10 check-ins total)
        // Let's create 9 check-ins today:
        // 6 completed check-outs earlier today (60-90 min)
        // 3 active members currently inside (CheckOutTime = null, checked in 15-90 mins ago)
        var todayMembers = members.OrderBy(_ => random.Next()).Take(9).ToList();

        // 6 completed earlier today
        for (var c = 0; c < 6; c++)
        {
            var m = todayMembers[c];
            var checkInHour = 7 + c; // between 7:00 and 12:00
            var checkIn = now.Date.AddHours(checkInHour).AddMinutes(random.Next(40));
            var durationMinutes = random.Next(60, 90);
            var checkOut = checkIn.AddMinutes(durationMinutes);

            attendances.Add(new AttendanceRecord
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymIdString,
                MemberId = m.Id,
                CheckInTime = DateTime.SpecifyKind(checkIn, DateTimeKind.Utc),
                CheckOutTime = DateTime.SpecifyKind(checkOut, DateTimeKind.Utc),
                Notes = "حضور اليوم - انتهى"
            });
        }

        // 3 currently inside: check-in between now - 15m and now - 80m, CheckOutTime = null
        var insideDelaysMinutes = new[] { 20, 45, 75 };
        for (var insideIdx = 0; insideIdx < 3; insideIdx++)
        {
            var m = todayMembers[6 + insideIdx];
            var checkIn = now.AddMinutes(-insideDelaysMinutes[insideIdx]);

            attendances.Add(new AttendanceRecord
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymIdString,
                MemberId = m.Id,
                CheckInTime = DateTime.SpecifyKind(checkIn, DateTimeKind.Utc),
                CheckOutTime = null,
                Notes = "متواجد الآن في الجيم"
            });
        }

        // Save everything
        dbContext.Subscriptions.AddRange(subscriptions);
        dbContext.PaymentRecords.AddRange(payments);
        dbContext.AttendanceRecords.AddRange(attendances);
        await dbContext.SaveChangesAsync(cancellationToken);

        var todayStart = now.Date;
        var todayAttendanceCount = attendances.Count(a => a.CheckInTime >= todayStart);
        var currentlyInsideCount = attendances.Count(a => a.CheckOutTime == null && a.CheckInTime >= now.AddMinutes(-120));

        return new PopulateHistoryResult(
            Success: true,
            Message: "30-day realistic history successfully seeded.",
            GymId: targetGymId,
            MembersCount: members.Count,
            NewMembersAdded: newMembersAdded,
            SubscriptionsCreated: subscriptions.Count,
            ActiveSubscriptionsCount: activeCount,
            ExpiringSoonSubscriptionsCount: expiringSoonCount,
            ExpiredSubscriptionsCount: expiredCount,
            PaymentsCreated: payments.Count,
            DropInPaymentsCreated: dropInPaymentsCount,
            TotalPaymentsRevenue: payments.Sum(p => p.Amount),
            AttendanceRecordsCreated: attendances.Count,
            TodayAttendanceRecordsCreated: todayAttendanceCount,
            CurrentlyInsideCount: currentlyInsideCount
        );
    }
}
