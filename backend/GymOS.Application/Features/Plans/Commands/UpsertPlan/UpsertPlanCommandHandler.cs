using GymOS.Application.Features.Plans.DTOs;
using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;

namespace GymOS.Application.Features.Plans.Commands.UpsertPlan;

public class UpsertPlanCommandHandler(IGymDbContext context, ICurrentTenantService tenantService)
    : IRequestHandler<UpsertPlanCommand, UpsertPlanResult>
{
    public async Task<UpsertPlanResult> Handle(UpsertPlanCommand request, CancellationToken cancellationToken)
    {
        if (request.Price < 0 || request.DurationInDays <= 0)
            return new UpsertPlanResult(false, "السعر أو المدة غير صحيحة.", null);

        if (request.Id == null || request.Id == Guid.Empty)
        {
            var newPlan = new Plan
            {
                Id = Guid.NewGuid(),
                TenantId = new Guid(tenantService.TenantId!),
                Name = request.Name.Trim(),
                Description = request.Description?.Trim(),
                Price = request.Price,
                DurationInDays = request.DurationInDays,
                IsActive = request.IsActive
            };

            context.Plans.Add(newPlan);
            await context.SaveChangesAsync(cancellationToken);
            return new UpsertPlanResult(true, "تم إضافة الباقة بنجاح.", newPlan.Id);
        }

        var existingPlan = await context.Plans
            .FirstOrDefaultAsync(p => p.Id == request.Id, cancellationToken);

        if (existingPlan == null)
            return new UpsertPlanResult(false, "الباقة غير موجودة.", null);

        existingPlan.Name = request.Name.Trim();
        existingPlan.Description = request.Description?.Trim();
        existingPlan.Price = request.Price;
        existingPlan.DurationInDays = request.DurationInDays;
        existingPlan.IsActive = request.IsActive;

        await context.SaveChangesAsync(cancellationToken);
        return new UpsertPlanResult(true, "تم تحديث الباقة بنجاح.", existingPlan.Id);
    }
}