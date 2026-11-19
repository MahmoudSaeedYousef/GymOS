namespace GymOS.Application.DTOs.Plans;

public record PlanDto(Guid Id, string Name, decimal Price, int DurationInDays, int? MaxSessions);
