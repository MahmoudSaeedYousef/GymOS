namespace GymOS.Application.Features.Plans.DTOs;

public record UpsertPlanResult(bool IsSuccess, string Message, Guid? PlanId);