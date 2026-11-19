namespace GymOS.Application.Features.Members.DTOs;

public record PagedResult<T>(
    List<T> Items,
    string? NextCursor,
    bool HasMore);