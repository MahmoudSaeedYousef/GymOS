// public record DashboardStatsDto(
//     int ActiveMembersCount,
//     int TodayCheckInsCount,
//     int ExpiredSubscriptionsCount,
//     decimal MonthlyRevenue,
//     int CurrentInside);
    
public record DashboardStatsDto(
    int ActiveMembersCount,
    int TodayCheckInsCount,
    int ExpiredSubscriptionsCount,
    decimal MonthlyRevenue,
    decimal TodayRevenue,
    decimal MonthlyDropInRevenue,
    int CurrentInside
);