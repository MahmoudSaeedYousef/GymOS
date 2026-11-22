using MediatR;

namespace GymOS.Application.Features.Members.Commands.UpdateMember;

public record UpdateMemberCommand(
    string Id,
    string FullName,
    string PhoneNumber) : IRequest<UpdateMemberResult>;
