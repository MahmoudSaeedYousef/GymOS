namespace GymOS.Domain.Entities;

public class IdempotencyRecord
{
    public Guid Id { get; set; } = Guid.CreateVersion7();
    public Guid GymId { get; set; }
    public string IdempotencyKey { get; set; } = string.Empty;
    public string RequestPath { get; set; } = string.Empty;
    public int StatusCode { get; set; }
    public string ResponseBody { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAtUtc { get; set; }

    public IdempotencyRecord()
    {
        ExpiresAtUtc = CreatedAtUtc.AddHours(48);
    }
}
