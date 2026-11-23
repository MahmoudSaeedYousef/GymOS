namespace GymOS.Application.Features.Members.Commands.DeleteMemberPhoto;

public record DeleteMemberPhotoResult(bool IsSuccess, int StatusCode, string? ErrorMessage = null)
{
    public static DeleteMemberPhotoResult Success() => new(true, 200);
    public static DeleteMemberPhotoResult NotFound(string message) => new(false, 404, message);
    public static DeleteMemberPhotoResult BadRequest(string message) => new(false, 400, message);
}
