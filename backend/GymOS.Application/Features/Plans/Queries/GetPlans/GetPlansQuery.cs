using GymOS.Application.DTOs.Plans;
using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Plans.Queries.GetPlans;
public record GetPlansQuery : IRequest<List<PlanDto>>;
