using GymOS.Domain.Enums;
using MediatR;

namespace GymOS.Application.Features.Members.Commands.UpdateMember;

public record UpdateMemberCommand(
    string Id,
    string FullName,
    string PhoneNumber,
    Gender? Gender = null) : IRequest<UpdateMemberResult>;
