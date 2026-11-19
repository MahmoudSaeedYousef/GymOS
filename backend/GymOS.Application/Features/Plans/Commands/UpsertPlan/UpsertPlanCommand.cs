using GymOS.Application.Features.Plans.DTOs;
using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;

namespace GymOS.Application.Features.Plans.Commands.UpsertPlan;

public record UpsertPlanCommand(
    Guid? Id,
    string Name,
    string? Description,
    decimal Price,
    int DurationInDays,
    bool IsActive = true
) : IRequest<UpsertPlanResult>;