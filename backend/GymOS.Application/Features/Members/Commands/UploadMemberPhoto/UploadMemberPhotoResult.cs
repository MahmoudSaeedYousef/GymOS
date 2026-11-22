namespace GymOS.Application.Features.Members.Commands.UploadMemberPhoto;

public record UploadMemberPhotoResult(
    bool IsSuccess,
    string? PhotoUrl = null,
    string? ErrorMessage = null,
    int StatusCode = 200)
{
    public static UploadMemberPhotoResult Success(string photoUrl) =>
        new(true, photoUrl, null, 200);

    public static UploadMemberPhotoResult NotFound(string message = "Member not found.") =>
        new(false, null, message, 404);

    public static UploadMemberPhotoResult BadRequest(string message) =>
        new(false, null, message, 400);
}
