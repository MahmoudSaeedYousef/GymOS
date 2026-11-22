namespace GymOS.Application.Features.Members.DTOs;

public record MemberPlanSummaryDto(
    Guid? PlanId,
    string PlanName,
    int Count
);

public record MembersSummaryDto(
    int Total,
    int Active,
    int Expired,
    int ExpiringSoon,
    List<MemberPlanSummaryDto> Plans
);
