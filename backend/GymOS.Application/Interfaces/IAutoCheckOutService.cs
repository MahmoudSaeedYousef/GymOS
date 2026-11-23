namespace GymOS.Application.Interfaces;

public interface IAutoCheckOutService
{
    Task<int> ProcessAutoCheckOutAsync(DateTime? utcNow = null, CancellationToken cancellationToken = default);
}
