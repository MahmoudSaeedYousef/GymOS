namespace GymOS.Domain.Entities;

public class GymTenant
{
    public Guid Id { get; set; } = Guid.CreateVersion7();
    public string Name { get; set; } = string.Empty;
    public string Subdomain { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public int DefaultSessionDurationMinutes { get; set; } = 120; // ساعتين افتراضياً
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}