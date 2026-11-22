using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using GymOS.Application.Features.Attendance.Commands.CheckIn;
using GymOS.Application.Features.Attendance.Commands.CheckOut;
using GymOS.Application.Features.Attendance.Queries.GetCurrentInside; // الـ using من الـ Application Layer
using GymOS.Application.Features.Attendance.Queries.GetAttendanceHistory;

namespace GymOS.Api.Endpoints;

public static class AttendanceEndpoints
{
    public static void MapAttendanceEndpoints(this IEndpointRouteBuilder app)
    {
        MapGroup(app.MapGroup("/api/attendance").RequireAuthorization());
        MapGroup(app.MapGroup("/api/gym/attendance").RequireAuthorization());
    }

    private static void MapGroup(RouteGroupBuilder group)
    {
        group.MapPost("/check-in", async (CheckInCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            
            if (!result.IsSuccess)
                return Results.BadRequest(new { Message = result.Message });

            return Results.Ok(new { Message = result.Message, AttendanceId = result.AttendanceId });
        });

        group.MapGet("/", async (DateTime? startDate, DateTime? endDate, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetAttendanceHistoryQuery(startDate, endDate));
            return Results.Ok(result);
        });

        group.MapGet("/current-inside", async (IMediator mediator) =>
        {
            var result = await mediator.Send(new GetCurrentInsideQuery());
            return Results.Ok(result);
        });

        group.MapPost("/check-out", async (CheckOutCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.IsSuccess ? Results.Ok(result) : Results.BadRequest(result);
        });

        group.MapPost("/{recordId:guid}/check-out", async (Guid recordId, CheckOutCommand? command, IMediator mediator) =>
        {
            var cmd = (command ?? new CheckOutCommand(recordId)) with { RecordId = recordId };
            var result = await mediator.Send(cmd);
            return result.IsSuccess ? Results.Ok(result) : Results.BadRequest(result);
        });
    }
}