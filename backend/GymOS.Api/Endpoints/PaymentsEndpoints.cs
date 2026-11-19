using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using GymOS.Application.Features.Payments.Commands.RenewSubscription;
using GymOS.Application.Features.Payments.Queries.GetPayments;

namespace GymOS.Api.Endpoints;

public static class PaymentsEndpoints
{
    public static void MapPaymentsEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/payments").RequireAuthorization();

        group.MapPost("/renew", async (RenewSubscriptionCommand command, IMediator mediator) =>
        {
            var result = await mediator.Send(command);
            
            if (!result.IsSuccess)
                return Results.BadRequest(new { Message = result.Message });

            return Results.Ok(new 
            { 
                Message = result.Message,
                NewEndDate = result.NewEndDate 
            });
        });
        group.MapGet("/", async (string? period, IMediator mediator) =>
        {
            var result = await mediator.Send(new GetPaymentsQuery(period ?? "month"));
            return Results.Ok(result);
        });
    }
}