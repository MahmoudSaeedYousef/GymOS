using System.Text.Json.Serialization;
using GymOS.Domain.Enums;

namespace GymOS.Application.Features.Members.DTOs;

public record MemberDto(
    string Id,
    string FullName,
    string PhoneNumber,
    string? ActivePlanName,
    DateOnly? SubscriptionEndDate,
    string SubscriptionStatus,
    [property: JsonPropertyName("photoUrl")] string? PhotoUrl = null,
    [property: JsonPropertyName("gender")] Gender Gender = Gender.Unspecified);