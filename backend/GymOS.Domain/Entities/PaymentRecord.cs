using GymOS.Domain.Enums;

namespace GymOS.Domain.Entities;

public class PaymentRecord
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    // Multi-tenancy
    public string TenantId { get; set; } = string.Empty;
    
    // ربط المشترك
    public string MemberId { get; set; } = string.Empty;
    public ApplicationUser Member { get; set; } = null!;
    
    // بيانات الدفع
    public decimal Amount { get; set; }
    public PaymentMethod Method { get; set; }
    public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
    
    // الباقة اللي اشترك فيها (عشان لو سعر الباقة اتغير مستقبلاً، نكون محتفظين بالرقم اللي دفعه واسم الباقة وقتها)
    public Guid? PlanId { get; set; }
    public Plan? Plan { get; set; }
    
    public Guid? OperationId { get; set; }        // opId لمنع التكرار وجاهزية O1
    public bool IsDropIn { get; set; } = false;   // لفصل إيراد الحصص عن الاشتراكات في التقارير
    public Guid? ReversedPaymentId { get; set; }
    
    public string? Notes { get; set; } // مثال: "رقم عملية إنستاباي: 123456"
}