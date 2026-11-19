using GymOS.Application.Features.Attendance.DTOs;
using MediatR;

namespace GymOS.Application.Features.Attendance.Queries.GetCurrentInside;
public record GetCurrentInsideQuery() : IRequest<List<CurrentInsideMemberDto>>;