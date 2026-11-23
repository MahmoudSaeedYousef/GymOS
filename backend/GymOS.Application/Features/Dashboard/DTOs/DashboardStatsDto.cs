public record DailyAttendanceStatDto(
    DateOnly Date,
    int Count
);

public record DailyRevenueStatDto(
    DateOnly Date,
    decimal Amount
);

public record DashboardStatsDto(
    int ActiveMembersCount,
    int TodayCheckInsCount,
    int ExpiredSubscriptionsCount,
    decimal MonthlyRevenue,
    decimal TodayRevenue,
    decimal MonthlyDropInRevenue,
    int CurrentInside,
    List<DailyAttendanceStatDto>? Last7DaysAttendance = null,
    List<DailyRevenueStatDto>? Last7DaysRevenue = null
);