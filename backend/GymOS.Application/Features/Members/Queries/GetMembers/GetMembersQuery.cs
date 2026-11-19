using GymOS.Application.Features.Members.DTOs;
using MediatR;

namespace GymOS.Application.Features.Members.Queries.GetMembers;

public record GetMembersQuery(
    string? SearchTerm,
    string? Cursor,
    string? Filter,
    string? SortBy = "newest",
    int PageSize = 20) : IRequest<PagedResult<MemberDto>>;