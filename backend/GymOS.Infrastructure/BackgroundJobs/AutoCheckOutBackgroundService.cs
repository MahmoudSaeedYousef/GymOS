namespace GymOS.Infrastructure.BackgroundJobs;

using GymOS.Application.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

public class AutoCheckOutBackgroundService(
    IServiceScopeFactory scopeFactory,
    ILogger<AutoCheckOutBackgroundService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(15);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("AutoCheckOutBackgroundService started with interval {Interval}.", Interval);

        using var timer = new PeriodicTimer(Interval);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await timer.WaitForNextTickAsync(stoppingToken);

                using var scope = scopeFactory.CreateScope();
                var service = scope.ServiceProvider.GetRequiredService<IAutoCheckOutService>();
                await service.ProcessAutoCheckOutAsync(null, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error occurred during automatic check-out job execution.");
            }
        }

        logger.LogInformation("AutoCheckOutBackgroundService stopped.");
    }
}
