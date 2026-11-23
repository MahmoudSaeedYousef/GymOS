using MediatR;

namespace GymOS.Application.Features.Members.Commands.DeleteMemberPhoto;

public record DeleteMemberPhotoCommand(string MemberId) : IRequest<DeleteMemberPhotoResult>;
