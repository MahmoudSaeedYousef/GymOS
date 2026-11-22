using MediatR;

namespace GymOS.Application.Features.Members.Commands.UploadMemberPhoto;

public record UploadMemberPhotoCommand(
    string MemberId,
    Stream FileStream,
    string FileName,
    long FileLength) : IRequest<UploadMemberPhotoResult>;
