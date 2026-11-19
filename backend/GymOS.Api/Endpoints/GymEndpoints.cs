using GymOS.Application.Features.Members.Commands.CreateMember;
using GymOS.Application.Features.Members.Queries.GetMembers;
using GymOS.Application.Features.Plans;
using GymOS.Application.Features.Plans.Commands.CreatePlan;
using GymOS.Application.Features.Plans.Queries.GetPlans;
using GymOS.Application.Features.Subscriptions;
using GymOS.Application.Features.Subscriptions.Commands.SubscribeMember;
using MediatR;

namespace GymOS.Api.Endpoints;

public static class GymEndpoints
{
    public static void MapGymEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/gym").RequireAuthorization();

        group.MapPost("/plans", async (CreatePlanCommand command, ISender sender) =>
        {
            var id = await sender.Send(command);
            return Results.Created($"/api/gym/plans/{id}", new { id });
        });

        group.MapGet("/plans", async (ISender sender) =>
        {
            var plans = await sender.Send(new GetPlansQuery());
            return Results.Ok(plans);
        });

        group.MapPost("/subscriptions", async (SubscribeMemberCommand command, ISender sender) =>
        {
            var id = await sender.Send(command);
            return Results.Created($"/api/gym/subscriptions/{id}", new { id });
        });
        group.MapPost("/members", async (CreateMemberCommand command, ISender sender) =>
        {
            var id = await sender.Send(command);
            return Results.Created($"/api/gym/members/{id}", new { id });
        });

        group.MapGet("/members", async (string? search, string? cursor,string? filter, string? sortBy, int? pageSize, ISender sender) =>
        {
            var result = await sender.Send(new GetMembersQuery(search, cursor,filter, sortBy, pageSize ?? 20));
            return Results.Ok(result);
        });
    }
}