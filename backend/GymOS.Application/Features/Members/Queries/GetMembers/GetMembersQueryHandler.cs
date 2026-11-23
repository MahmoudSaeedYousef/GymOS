using System.Globalization;
using GymOS.Application.Features.Members.DTOs;
using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Application.Interfaces;

namespace GymOS.Application.Features.Members.Queries.GetMembers;

public class GetMembersQueryHandler(IGymDbContext context)
    : IRequestHandler<GetMembersQuery, PagedResult<MemberDto>>
{
    public async Task<PagedResult<MemberDto>> Handle(GetMembersQuery request, CancellationToken cancellationToken)
    {
        var pageSize = Math.Clamp(request.PageSize, 1, 50);
        var now = DateTime.UtcNow;
        var today = now.Date;
        var sortBy = (request.SortBy ?? "newest").ToLower();

        var isTodayFilter = string.Equals(request.Filter, "today", StringComparison.OrdinalIgnoreCase);

        var query = context.Users.AsNoTracking();
        if (!isTodayFilter)
        {
            query = query.Where(c => !c.IsGuest);
        }

        // 1. الفلترة
        var fiveDaysFromToday = today.AddDays(5);
        query = request.Filter?.ToLower() switch
        {
            "active" => query.Where(u => u.SubscriptionEndDate >= now),
            "expired" => query.Where(u => u.SubscriptionEndDate < now || u.SubscriptionEndDate == null),
            "expiring_soon" or "expiringsoon" => query.Where(u =>
                u.SubscriptionEndDate >= today &&
                u.SubscriptionEndDate <= fiveDaysFromToday),
            "today" => query.Where(u => context.AttendanceRecords
                .Any(a => a.MemberId == u.Id && a.CheckInTime >= today)),
            _ => query
        };
        // 2. البحث السريع (GIN Trigram & Phone Index)
        if (!string.IsNullOrWhiteSpace(request.SearchTerm))
        {
            var term = request.SearchTerm.Trim();
            query = query.Where(u =>
                EF.Functions.Like(u.FullName, $"%{term}%") ||
                (u.PhoneNumber != null && u.PhoneNumber.StartsWith(term)));
        }

        // إسقاط البيانات المطلوبة للترتيب والكيرسور في استعلام واحد
        var projected = query.Select(u => new
        {
            u.Id,
            u.FullName,
            u.PhoneNumber,
            u.SubscriptionEndDate,
            u.PhotoUrl,
            u.Gender,
            u.IsGuest,
            LatestSub = context.Subscriptions
                .Where(s => s.MemberId == u.Id)
                .OrderByDescending(s => s.EndDate)
                .Select(s => new
                {
                    PlanName = s.Plan.Name,
                    s.StartDate,
                    s.EndDate,
                    Status = s.Status.ToString()
                })
                .FirstOrDefault(),
            LastCheckIn = context.AttendanceRecords
                .Where(a => a.MemberId == u.Id)
                .Max(a => (DateTime?)a.CheckInTime)
        });

        // فك الـ Composite Cursor ("sortValue|id")
        string? cursorVal = null;
        string? cursorId = null;
        if (!string.IsNullOrWhiteSpace(request.Cursor))
        {
            var sepIndex = request.Cursor.LastIndexOf('|');
            if (sepIndex > 0)
            {
                cursorVal = request.Cursor[..sepIndex];
                cursorId = request.Cursor[(sepIndex + 1)..];
            }
            else
            {
                cursorId = request.Cursor;
            }
        }

        // 3. تطبيق Keyset Pagination + الترتيب حسب الاختيار
        switch (sortBy)
        {
            case "name":
                if (cursorVal != null && cursorId != null)
                {
                    projected = projected.Where(x =>
                        string.Compare(x.FullName, cursorVal) > 0 ||
                        (x.FullName == cursorVal && string.Compare(x.Id, cursorId) > 0));
                }
                projected = projected.OrderBy(x => x.FullName).ThenBy(x => x.Id);
                break;

            case "expiringsoon": // الأقرب للانتهاء (الساريين أولاً ثم المنتهيين)
                var minDate = DateTime.MinValue;
                if (cursorVal != null && cursorId != null &&
                    DateTime.TryParse(cursorVal, null, DateTimeStyles.RoundtripKind, out var cExp))
                {
                    projected = projected.Where(x =>
                        (x.SubscriptionEndDate ?? minDate) > cExp ||
                        ((x.SubscriptionEndDate ?? minDate) == cExp && string.Compare(x.Id, cursorId) > 0));
                }
                projected = projected
                    .OrderByDescending(x => x.SubscriptionEndDate >= now)
                    .ThenBy(x => x.SubscriptionEndDate ?? minDate)
                    .ThenBy(x => x.Id);
                break;

            case "enddatedesc": // تاريخ الانتهاء (الأبعد أولاً)
                var floorDate = DateTime.MinValue;
                if (cursorVal != null && cursorId != null &&
                    DateTime.TryParse(cursorVal, null, DateTimeStyles.RoundtripKind, out var cEnd))
                {
                    projected = projected.Where(x =>
                        (x.SubscriptionEndDate ?? floorDate) < cEnd ||
                        ((x.SubscriptionEndDate ?? floorDate) == cEnd && string.Compare(x.Id, cursorId) > 0));
                }
                projected = projected
                    .OrderByDescending(x => x.SubscriptionEndDate ?? floorDate)
                    .ThenBy(x => x.Id);
                break;

            case "plan": // حسب اسم الباقة
                if (cursorVal != null && cursorId != null)
                {
                    projected = projected.Where(x =>
                        string.Compare(x.LatestSub != null ? x.LatestSub.PlanName : "", cursorVal) > 0 ||
                        ((x.LatestSub != null ? x.LatestSub.PlanName : "") == cursorVal && string.Compare(x.Id, cursorId) > 0));
                }
                projected = projected
                    .OrderBy(x => x.LatestSub != null ? x.LatestSub.PlanName : "")
                    .ThenBy(x => x.Id);
                break;

            case "lastcheckin": // آخر حضور في الجيم
                var baseCheckIn = DateTime.MinValue;
                if (cursorVal != null && cursorId != null &&
                    DateTime.TryParse(cursorVal, null, DateTimeStyles.RoundtripKind, out var cCheck))
                {
                    projected = projected.Where(x =>
                        (x.LastCheckIn ?? baseCheckIn) < cCheck ||
                        ((x.LastCheckIn ?? baseCheckIn) == cCheck && string.Compare(x.Id, cursorId) > 0));
                }
                projected = projected
                    .OrderByDescending(x => x.LastCheckIn ?? baseCheckIn)
                    .ThenBy(x => x.Id);
                break;

            case "newest": // الأحدث اشتراكاً (الافتراضي)
            default:
                var baseStart = DateOnly.MinValue;
                if (cursorVal != null && cursorId != null &&
                    DateOnly.TryParse(cursorVal, CultureInfo.InvariantCulture, DateTimeStyles.None, out var cStart))
                {
                    projected = projected.Where(x =>
                        ((x.LatestSub != null ? x.LatestSub.StartDate : baseStart) < cStart) ||
                        ((x.LatestSub != null ? x.LatestSub.StartDate : baseStart) == cStart && string.Compare(x.Id, cursorId) > 0));
                }
                projected = projected
                    .OrderByDescending(x => x.LatestSub != null ? x.LatestSub.StartDate : baseStart)
                    .ThenBy(x => x.Id);
                break;
        }

        // جلب PageSize + 1 بدون COUNT(*)
        var rawUsers = await projected
            .Take(pageSize + 1)
            .ToListAsync(cancellationToken);

        var hasMore = rawUsers.Count > pageSize;
        var pageUsers = rawUsers.Take(pageSize).ToList();

        var items = pageUsers
            .Select(u =>
            {
                var isSingleSession = u.IsGuest;
                var displayName = isSingleSession && (string.IsNullOrWhiteSpace(u.FullName) || u.FullName == "زائر حصة مفردة")
                    ? "حصة منفردة"
                    : u.FullName;
                var planName = isSingleSession
                    ? (u.LatestSub?.PlanName ?? "حصة منفردة")
                    : u.LatestSub?.PlanName;
                var status = isSingleSession
                    ? "Expired"
                    : ((u.LatestSub == null || u.SubscriptionEndDate == null || u.SubscriptionEndDate < now) ? "Expired" : "Active");

                return new MemberDto(
                    u.Id,
                    displayName,
                    u.PhoneNumber ?? "",
                    planName,
                    u.LatestSub?.EndDate,
                    status,
                    isSingleSession ? null : u.PhotoUrl,
                    u.Gender,
                    IsGuest: u.IsGuest,
                    IsSingleSession: isSingleSession);
            })
            .ToList();

        // بناء الـ NextCursor للصفحة الجاية
        string? nextCursor = null;
        if (hasMore && pageUsers.Count > 0)
        {
            var last = pageUsers.Last();
            var lastSortVal = sortBy switch
            {
                "name" => last.FullName,
                "expiringsoon" => (last.SubscriptionEndDate ?? DateTime.MinValue).ToString("O"),
                "enddatedesc" => (last.SubscriptionEndDate ?? DateTime.MinValue).ToString("O"),
                "plan" => last.LatestSub?.PlanName ?? "",
                "lastcheckin" => (last.LastCheckIn ?? DateTime.MinValue).ToString("O"),
                _ => (last.LatestSub?.StartDate ?? DateOnly.MinValue).ToString("O", CultureInfo.InvariantCulture)
            };
            nextCursor = $"{lastSortVal}|{last.Id}";
        }

        return new PagedResult<MemberDto>(items, nextCursor, hasMore);
    }
}