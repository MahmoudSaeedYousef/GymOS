using GymOS.Application.Features.Members.DTOs;
using MediatR;

namespace GymOS.Application.Features.Members.Queries.GetMemberById;

public record GetMemberByIdQuery(string Id) : IRequest<MemberDto?>;
