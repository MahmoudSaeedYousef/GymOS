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

        const int targetMemberCount = 60;
        var newMembersAdded = 0;
        if (members.Count < targetMemberCount)
        {
            var maleFirstNames = new[]
            {
                "أحمد", "محمد", "محمود", "كريم", "عمر", "يوسف", "خالد", "علي", "إبراهيم", "طارق",
                "سمير", "شريف", "علاء", "مصطفى", "حسام", "هشام", "وليد", "ياسين", "زياد", "حمزة",
                "بلال", "آسر", "حازم", "عمرو", "تامر", "رامي", "هاني", "ماجد", "وائل", "أيمن",
                "معتز", "شادي", "أدهم", "فارس", "مروان", "سيف", "باسل"
            };

            var femaleFirstNames = new[]
            {
                "سارة", "نور", "مريم", "سلمى", "ياسمين", "فريدة", "هند", "ندى", "أميرة", "رنا",
                "دينا", "منى", "آية", "حبيبة", "ملك", "شهد", "روان", "جنا", "ليلى", "فاطمة",
                "خديجة", "عائشة", "زينب", "ريم", "هبة", "إسراء", "دعاء", "ريهام", "نوران", "مروة"
            };

            var middleOrLastNames = new[]
            {
                "حسن", "علي", "إبراهيم", "طارق", "سمير", "شريف", "علاء", "مصطفى", "حسام", "هشام",
                "وليد", "كمال", "فهمي", "فاروق", "الجندي", "الشناوي", "عبد العزيز", "الدسوقي", "البدري", "المهدي",
                "الشافعي", "النجار", "الحداد", "الصاوي", "القاضي", "زهران", "عثمان", "منصور", "صلاح", "راضي",
                "سالم", "عطية", "سليمان", "رزق", "غنيم", "مختار", "جمال", "صبري", "جاد", "الهواري"
            };

            var phonePrefixes = new[] { "010", "011", "012", "015" };
            var existingPhones = (await dbContext.Users
                .IgnoreQueryFilters()
                .Where(u => u.TenantId == targetGymId && u.PhoneNumber != null)
                .Select(u => u.PhoneNumber!)
                .ToListAsync(cancellationToken)).ToHashSet();

            var randomGen = new Random(1337);
            var attempts = 0;

            while (members.Count < targetMemberCount && attempts < 2000)
            {
                attempts++;
                var isFemale = (members.Count % 2 == 1);
                var gender = isFemale ? Gender.Female : Gender.Male;
                var f = isFemale
                    ? femaleFirstNames[randomGen.Next(femaleFirstNames.Length)]
                    : maleFirstNames[randomGen.Next(maleFirstNames.Length)];
                var m = middleOrLastNames[randomGen.Next(middleOrLastNames.Length)];
                var l = middleOrLastNames[randomGen.Next(middleOrLastNames.Length)];
                var fullName = $"{f} {m} {l}";

                var prefix = phonePrefixes[randomGen.Next(phonePrefixes.Length)];
                var phoneNum = $"{prefix}{randomGen.Next(10000000, 99999999)}";

                if (existingPhones.Contains(phoneNum))
                {
                    continue;
                }

                existingPhones.Add(phoneNum);
                var suffix = Guid.NewGuid().ToString("N")[..6];
                var newMember = new ApplicationUser
                {
                    Id = Guid.CreateVersion7().ToString(),
                    TenantId = targetGymId,
                    Type = UserType.Member,
                    FullName = fullName,
                    PhoneNumber = phoneNum,
                    UserName = $"{phoneNum}_{suffix}",
                    NormalizedUserName = $"{phoneNum}_{suffix}".ToUpperInvariant(),
                    Gender = gender,
                    IsGuest = false
                };

                dbContext.Users.Add(newMember);
                members.Add(newMember);
                newMembersAdded++;
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

        // Pre-determine a varied distribution of active start dates across 0..29 days ago:
        // Weekdays and days vary so daily payment revenue across past 30 days is noticeably varied (high, medium, low days).
        // Daily subscription joining target weights for past 30 days (day 0 = today, day 29 = 29 days ago)
        var dailyActiveMemberSlots = new List<int>();
        var activeDaysDistribution = new int[30];
        // Cycle pattern with distinct high, medium, and low revenue days:
        for (var d = 0; d < 30; d++)
        {
            var dayWeight = (d % 7) switch
            {
                0 => 3, // High (e.g. today / Sat)
                1 => 4, // High
                2 => 2, // Medium
                3 => 3, // High
                4 => 1, // Low
                5 => 0, // Very low / weekend
                _ => 2  // Medium
            };
            activeDaysDistribution[d] = dayWeight;
        }

        // Fill slots based on weights
        for (var d = 0; d < 30; d++)
        {
            for (var w = 0; w < activeDaysDistribution[d]; w++)
            {
                dailyActiveMemberSlots.Add(d);
            }
        }

        var activeSlotIndex = 0;

        for (var i = 0; i < totalMembers; i++)
        {
            var member = members[i];
            var plan = durationPlans[i % durationPlans.Count];
            var planDuration = plan.DurationInDays > 0 ? plan.DurationInDays : 30;
            var planPrice = plan.Price > 0 ? plan.Price : 500m;

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
                // Active: distribute starts across past 0 to 25 days ago, ensuring subEndDate > today
                var daysAgo = dailyActiveMemberSlots.Count > 0
                    ? dailyActiveMemberSlots[activeSlotIndex++ % dailyActiveMemberSlots.Count]
                    : (random.Next(25));

                // Guard against startAgo >= planDuration so subEndDate is strictly > today
                var maxStartAgo = Math.Max(0, planDuration - 1);
                var startAgo = Math.Min(daysAgo, maxStartAgo);

                subStartDate = today.AddDays(-startAgo);
                subEndDate = subStartDate.AddDays(planDuration);
                if (subEndDate <= today)
                {
                    subEndDate = today.AddDays(Math.Max(5, planDuration - startAgo));
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
                Amount = planPrice,
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
        // Varied amounts and days (e.g. distinct high/med/low traffic days)
        var dropInPlanObj = existingPlans.FirstOrDefault(p => p.Kind == PlanKind.VisitPack && p.VisitsIncluded == 1)
                            ?? existingPlans.FirstOrDefault(p => p.Kind == PlanKind.VisitPack)
                            ?? existingPlans.First();
        var dropInPrice = dropInPlanObj.Price > 0 ? dropInPlanObj.Price : 60m;

        var dropInPaymentsCount = 0;
        // 10 drop-ins on previous days
        // Spread across past 30 days with varied distribution (some clustered on peak days, some solitary)
        var dropInDayOffsets = new[] { 1, 1, 2, 3, 5, 8, 10, 15, 21, 28 };
        for (var d = 0; d < 10; d++)
        {
            var dayOffset = dropInDayOffsets[d];
            var dropInMember = members[(d + 5) % members.Count];
            var dropInDate = now.AddDays(-dayOffset).Date
                .AddHours(11 + random.Next(9))
                .AddMinutes(random.Next(60));

            // Vary drop-in price slightly (e.g. single session vs day pass / student)
            var dropInAmount = (d % 3 == 0) ? dropInPrice * 1.5m : dropInPrice;
            var method = paymentMethods[random.Next(paymentMethods.Length)];
            var dropInPayment = new PaymentRecord
            {
                Id = Guid.CreateVersion7(),
                TenantId = targetGymIdString,
                MemberId = dropInMember.Id,
                PlanId = dropInPlanObj.Id,
                Amount = dropInAmount,
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

        // 7. Generate Realistic 30-Day & 7-Day Attendance Records
        // Varied daily attendance: High (10-13), Medium (6-9), Low (2-4) depending on day of week and cycle
        // For today: 9 check-ins, with exactly 3 members currently inside (CheckOutTime = null, checked in within 15-90 min).
        var attendances = new List<AttendanceRecord>();

        // Previous 29 days attendance:
        for (var dayAgo = 29; dayAgo >= 1; dayAgo--)
        {
            var targetDay = now.AddDays(-dayAgo).Date;
            var dayOfWeek = targetDay.DayOfWeek;

            // Varied daily counts across last 7 and 30 days (High ~11-13, Med ~6-9, Low ~2-4)
            int targetDailyCount = dayOfWeek switch
            {
                DayOfWeek.Saturday => random.Next(11, 14), // High peak day
                DayOfWeek.Monday => random.Next(10, 13),   // High peak day
                DayOfWeek.Wednesday => random.Next(9, 12), // Medium-high day
                DayOfWeek.Sunday => random.Next(6, 9),     // Medium day
                DayOfWeek.Tuesday => random.Next(7, 10),   // Medium day
                DayOfWeek.Thursday => random.Next(5, 8),   // Medium-low day
                DayOfWeek.Friday => random.Next(2, 5),     // Low day (rest day in Egypt)
                _ => random.Next(6, 10)
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
