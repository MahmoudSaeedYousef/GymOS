using GymOS.Application.DTOs.Visits;
using GymOS.Application.Features.Visits.Commands.RecordDropInVisit;
using GymOS.Application.Features.Visits.Commands.VoidDropIn;
using MediatR;

namespace GymOS.Api.Endpoints;

public static class VisitEndpoints
{
    public static void MapVisitEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/visits")
            .WithTags("Visits")
            .RequireAuthorization();

        group.MapPost("/drop-in", async (RecordDropInVisitCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            return result.Succeeded ? Results.Ok(result) : Results.BadRequest(result);
        });

        group.MapPost("/drop-in/{paymentId:guid}/void", async (Guid paymentId, VoidDropInRequest body, IMediator mediator) =>
        {
            var result = await mediator.Send(new VoidDropInCommand(paymentId, body.Reason));
            return result.Succeeded ? Results.Ok(result) : Results.BadRequest(result);
        });
    }
}

