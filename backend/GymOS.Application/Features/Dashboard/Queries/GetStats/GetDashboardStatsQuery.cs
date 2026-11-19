using MediatR;
namespace GymOS.Application.Features.Dashboard.Queries.GetStats;
public record GetDashboardStatsQuery() : IRequest<DashboardStatsDto>;

