public record DashboardStatsDto(
    int ActiveMembersCount,
    int TodayCheckInsCount,
    int ExpiredSubscriptionsCount,
    decimal MonthlyRevenue,
    int CurrentInside);