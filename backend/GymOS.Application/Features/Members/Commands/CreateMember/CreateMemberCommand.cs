using MediatR;

namespace GymOS.Application.Features.Members.Commands.CreateMember;

public record CreateMemberCommand(
    string FullName,
    string PhoneNumber,
    Guid? PlanId,
    DateOnly? StartDate) : IRequest<string>;