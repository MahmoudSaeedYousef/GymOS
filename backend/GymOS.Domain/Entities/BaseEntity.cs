namespace GymOS.Domain.Common;

public interface ITenantEntity
{
    Guid TenantId { get; set; }
}

public abstract class BaseEntity : ITenantEntity
{
    // استخدام GUID v7 (مرتب زمنياً لمنع Index Fragmentation في الداتابيز)
    public Guid Id { get; set; } = Guid.CreateVersion7();
    public Guid TenantId { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false; // Soft Delete
}