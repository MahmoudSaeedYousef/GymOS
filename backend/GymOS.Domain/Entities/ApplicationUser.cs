using Microsoft.AspNetCore.Identity;

namespace GymOS.Domain.Entities;

public enum UserType
{
    Admin,
    Staff,
    Member
}

public class ApplicationUser : IdentityUser
{
    public string FullName { get; set; } = string.Empty;
    public UserType Type { get; set; }
    public Guid TenantId { get; set; }
    public DateTime? SubscriptionEndDate { get; set; }

    public virtual ICollection<AttendanceRecord> AttendanceRecords { get; set; } = new List<AttendanceRecord>();
    public virtual ICollection<PaymentRecord> PaymentRecords { get; set; } = new List<PaymentRecord>();
}