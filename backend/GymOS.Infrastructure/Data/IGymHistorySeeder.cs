namespace GymOS.Infrastructure.Data;

public interface IGymHistorySeeder
{
    Task<GymOS.Application.Features.Dev.PopulateHistoryResult> Seed30DayHistoryAsync(
        Guid? gymId = null,
        DateTime? anchorTimeUtc = null,
        CancellationToken cancellationToken = default);
}
