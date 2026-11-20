using GymOS.Application.Features.Visits.DTOs;
using MediatR;

namespace GymOS.Application.Features.Visits.Commands.VoidDropIn;

public record VoidDropInCommand(Guid PaymentId, string Reason) : IRequest<VoidDropInResult>;
