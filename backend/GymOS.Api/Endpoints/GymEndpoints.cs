using GymOS.Application.Features.Members.Commands.CreateMember;
using GymOS.Application.Features.Members.Commands.DeleteMemberPhoto;
using GymOS.Application.Features.Members.Commands.UpdateMember;
using GymOS.Application.Features.Members.Commands.UploadMemberPhoto;
using GymOS.Application.Features.Members.DTOs;
using GymOS.Application.Features.Members.Queries.GetMemberById;
using GymOS.Application.Features.Members.Queries.GetMembers;
using GymOS.Application.Features.Members.Queries.GetMembersSummary;
using GymOS.Application.Features.Plans;
using GymOS.Application.Features.Plans.Commands.CreatePlan;
using GymOS.Application.Features.Plans.Queries.GetPlans;
using GymOS.Application.Features.Subscriptions;
using GymOS.Application.Features.Subscriptions.Commands.SubscribeMember;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;

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

        group.MapPut("/members/{id}", async (string id, UpdateMemberRequest request, ISender sender) =>
        {
            var result = await sender.Send(new UpdateMemberCommand(id, request.FullName, request.PhoneNumber, request.Gender));
            if (!result.IsSuccess)
            {
                return result.StatusCode == 404
                    ? Results.NotFound(new { message = result.ErrorMessage })
                    : Results.BadRequest(new { message = result.ErrorMessage });
            }
            return Results.Ok(result.Member);
        }).RequireAuthorization(new AuthorizeAttribute { Roles = "Admin,Manager" });

        group.MapPost("/members/{id}/photo", async (string id, IFormFile? file, HttpRequest request, ISender sender) =>
        {
            var targetFile = file ?? (request.HasFormContentType ? (await request.ReadFormAsync()).Files.FirstOrDefault() : null);
            if (targetFile == null || targetFile.Length == 0)
            {
                return Results.BadRequest(new { message = "File is required and cannot be empty." });
            }

            await using var stream = targetFile.OpenReadStream();
            var result = await sender.Send(new UploadMemberPhotoCommand(id, stream, targetFile.FileName, targetFile.Length));
            if (!result.IsSuccess)
            {
                return result.StatusCode == 404
                    ? Results.NotFound(new { message = result.ErrorMessage })
                    : Results.BadRequest(new { message = result.ErrorMessage });
            }

            return Results.Ok(new { photoUrl = result.PhotoUrl });
        })
        .RequireAuthorization(new AuthorizeAttribute { Roles = "Admin,Manager" })
        .DisableAntiforgery();

        group.MapDelete("/members/{id}/photo", async (string id, ISender sender) =>
        {
            var result = await sender.Send(new DeleteMemberPhotoCommand(id));
            if (!result.IsSuccess)
            {
                return result.StatusCode == 404
                    ? Results.NotFound(new { message = result.ErrorMessage })
                    : Results.BadRequest(new { message = result.ErrorMessage });
            }

            return Results.NoContent();
        })
        .RequireAuthorization(new AuthorizeAttribute { Roles = "Admin,Manager" });

        group.MapGet("/members/summary", async (ISender sender) =>
        {
            var summary = await sender.Send(new GetMembersSummaryQuery());
            return Results.Ok(summary);
        });

        group.MapGet("/members", async (string? search, string? cursor,string? filter, string? sortBy, int? pageSize, ISender sender) =>
        {
            var result = await sender.Send(new GetMembersQuery(search, cursor,filter, sortBy, pageSize ?? 20));
            return Results.Ok(result);
        });

        group.MapGet("/members/{id}", async (string id, ISender sender) =>
        {
            var result = await sender.Send(new GetMemberByIdQuery(id));
            return result is not null ? Results.Ok(result) : Results.NotFound(new { message = "Member not found." });
        });

        // Map root /api/members routes to support direct /api/members pathing as well
        var membersGroup = app.MapGroup("/api/members").RequireAuthorization();

        membersGroup.MapGet("/summary", async (ISender sender) =>
        {
            var summary = await sender.Send(new GetMembersSummaryQuery());
            return Results.Ok(summary);
        });

        membersGroup.MapGet("/", async (string? search, string? cursor, string? filter, string? sortBy, int? pageSize, ISender sender) =>
        {
            var result = await sender.Send(new GetMembersQuery(search, cursor, filter, sortBy, pageSize ?? 20));
            return Results.Ok(result);
        });

        membersGroup.MapGet("/{id}", async (string id, ISender sender) =>
        {
            var result = await sender.Send(new GetMemberByIdQuery(id));
            return result is not null ? Results.Ok(result) : Results.NotFound(new { message = "Member not found." });
        });

        membersGroup.MapPut("/{id}", async (string id, UpdateMemberRequest request, ISender sender) =>
        {
            var result = await sender.Send(new UpdateMemberCommand(id, request.FullName, request.PhoneNumber, request.Gender));
            if (!result.IsSuccess)
            {
                return result.StatusCode == 404
                    ? Results.NotFound(new { message = result.ErrorMessage })
                    : Results.BadRequest(new { message = result.ErrorMessage });
            }
            return Results.Ok(result.Member);
        }).RequireAuthorization(new AuthorizeAttribute { Roles = "Admin,Manager" });

        membersGroup.MapPost("/{id}/photo", async (string id, IFormFile? file, HttpRequest request, ISender sender) =>
        {
            var targetFile = file ?? (request.HasFormContentType ? (await request.ReadFormAsync()).Files.FirstOrDefault() : null);
            if (targetFile == null || targetFile.Length == 0)
            {
                return Results.BadRequest(new { message = "File is required and cannot be empty." });
            }

            await using var stream = targetFile.OpenReadStream();
            var result = await sender.Send(new UploadMemberPhotoCommand(id, stream, targetFile.FileName, targetFile.Length));
            if (!result.IsSuccess)
            {
                return result.StatusCode == 404
                    ? Results.NotFound(new { message = result.ErrorMessage })
                    : Results.BadRequest(new { message = result.ErrorMessage });
            }

            return Results.Ok(new { photoUrl = result.PhotoUrl });
        })
        .RequireAuthorization(new AuthorizeAttribute { Roles = "Admin,Manager" })
        .DisableAntiforgery();

        membersGroup.MapDelete("/{id}/photo", async (string id, ISender sender) =>
        {
            var result = await sender.Send(new DeleteMemberPhotoCommand(id));
            if (!result.IsSuccess)
            {
                return result.StatusCode == 404
                    ? Results.NotFound(new { message = result.ErrorMessage })
                    : Results.BadRequest(new { message = result.ErrorMessage });
            }

            return Results.NoContent();
        })
        .RequireAuthorization(new AuthorizeAttribute { Roles = "Admin,Manager" });
    }
}