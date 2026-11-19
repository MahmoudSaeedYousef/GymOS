using GymOS.Application.DTOs.Plans;
using GymOS.Application.Interfaces;
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Features.Plans.Queries.GetPlans;


public class GetPlansQueryHandler(
    IGymDbContext context,
    ICacheService cache,
    ICurrentTenantService tenantService) : IRequestHandler<GetPlansQuery, List<PlanDto>>
{
    public async Task<List<PlanDto>> Handle(GetPlansQuery request, CancellationToken cancellationToken)
    {
        var tenantId = tenantService.TenantId
                       ?? throw new UnauthorizedAccessException("Tenant ID missing.");

        var cacheKey = $"plans:{tenantId}";

        // 1. نفحص الكاش الأول
        var cachedPlans = await cache.GetAsync<List<PlanDto>>(cacheKey, cancellationToken);
        if (cachedPlans is not null)
            return cachedPlans;

        // 2. لو مش موجود في الكاش، نجيبه من الداتابيز
        var plans = await context.Plans
            .AsNoTracking()
            .Where(p => p.IsActive)
            .Select(p => new PlanDto(p.Id, p.Name, p.Price, p.DurationInDays, p.MaxSessions))
            .ToListAsync(cancellationToken);

        // 3. نخزنه في الكاش لمدة ساعة
        await cache.SetAsync(cacheKey, plans, TimeSpan.FromHours(1), cancellationToken);

        return plans;
    }
}