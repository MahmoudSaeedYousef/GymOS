public record DailyAttendanceStatDto(
    DateOnly Date,
    int Count
);

public record DashboardStatsDto(
    int ActiveMembersCount,
    int TodayCheckInsCount,
    int ExpiredSubscriptionsCount,
    decimal MonthlyRevenue,
    decimal TodayRevenue,
    decimal MonthlyDropInRevenue,
    int CurrentInside,
    List<DailyAttendanceStatDto>? Last7DaysAttendance = null
);