using System.Text.Json.Serialization;

namespace GymOS.Application.Features.Members.DTOs;

public record MemberDto(
    string Id,
    string FullName,
    string PhoneNumber,
    string? ActivePlanName,
    DateOnly? SubscriptionEndDate,
    string SubscriptionStatus,
    [property: JsonPropertyName("photoUrl")] string? PhotoUrl = null);