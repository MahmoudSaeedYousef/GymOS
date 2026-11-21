namespace GymOS.Application.Features.Dev;

public record PopulateHistoryResult(
    bool Success,
    string Message,
    Guid GymId,
    int MembersCount,
    int NewMembersAdded,
    int SubscriptionsCreated,
    int ActiveSubscriptionsCount,
    int ExpiringSoonSubscriptionsCount,
    int ExpiredSubscriptionsCount,
    int PaymentsCreated,
    int DropInPaymentsCreated,
    decimal TotalPaymentsRevenue,
    int AttendanceRecordsCreated,
    int TodayAttendanceRecordsCreated,
    int CurrentlyInsideCount
);
