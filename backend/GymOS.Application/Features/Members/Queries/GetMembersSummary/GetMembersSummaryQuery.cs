using GymOS.Application.Features.Members.DTOs;
using MediatR;

namespace GymOS.Application.Features.Members.Queries.GetMembersSummary;

public record GetMembersSummaryQuery : IRequest<MembersSummaryDto>;
