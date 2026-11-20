namespace GymOS.Domain.Entities;

public class AttendanceRecord
{
    public Guid Id { get; set; } = Guid.CreateVersion7();
    
    // Multi-tenancy
    public string TenantId { get; set; } = string.Empty;
    
    // ربط المشترك (بافتراض إن المشترك عندك في جدول ApplicationUser، لو عامل له كلاس Member عدّل النوع)
    public string MemberId { get; set; } = string.Empty;
    public ApplicationUser Member { get; set; } = null!;
    
    // بيانات الحضور\\
    public DateTime CheckInTime { get; set; } = DateTime.UtcNow;
    public DateTime? CheckOutTime { get; set; }
    
    // عشان لو الكابتن سجله يدوي يكتب ملاحظة، أو لو دخل بـ QR
    public string? Notes { get; set; } 
}