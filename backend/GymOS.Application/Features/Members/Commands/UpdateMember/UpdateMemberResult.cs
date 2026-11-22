using GymOS.Application.Features.Members.DTOs;

namespace GymOS.Application.Features.Members.Commands.UpdateMember;

public record UpdateMemberResult(
    bool IsSuccess,
    string? ErrorMessage = null,
    MemberDto? Member = null,
    int StatusCode = 200)
{
    public static UpdateMemberResult Success(MemberDto member) =>
        new(true, null, member, 200);

    public static UpdateMemberResult NotFound(string message = "Member not found.") =>
        new(false, message, null, 404);

    public static UpdateMemberResult BadRequest(string message) =>
        new(false, message, null, 400);

    public static UpdateMemberResult Conflict(string message) =>
        new(false, message, null, 409);
}
