using GymOS.Application.Interfaces;
using GymOS.Domain.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Infrastructure.Data;

public class GymDbContext(
    DbContextOptions<GymDbContext> options,
    ICurrentTenantService currentTenantService) 
    : IdentityDbContext<ApplicationUser>(options), IGymDbContext // <-- ضيف ", IGymDbContext" هنا
{
    public DbSet<GymTenant> Tenants => Set<GymTenant>();
    public DbSet<Plan> Plans => Set<Plan>();
    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<AttendanceRecord> AttendanceRecords => Set<AttendanceRecord>();
    public DbSet<PaymentRecord> PaymentRecords => Set<PaymentRecord>();
    public DbSet<IdempotencyRecord> IdempotencyRecords => Set<IdempotencyRecord>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // تفعيل إضافة Trigram للبحث السريع
        builder.HasPostgresExtension("pg_trgm");

        // عزل البيانات لكل جيم (Multi-Tenancy)
        builder.Entity<Plan>().HasQueryFilter(p => !p.IsDeleted && p.TenantId.ToString() == currentTenantService.TenantId);
        builder.Entity<Subscription>().HasQueryFilter(s => !s.IsDeleted && s.TenantId.ToString() == currentTenantService.TenantId);
        builder.Entity<ApplicationUser>().HasQueryFilter(u => u.TenantId.ToString() == currentTenantService.TenantId);

        // Composite Index للبحث السريع بالتليفون داخل نفس الجيم
        builder.Entity<ApplicationUser>()
            .HasIndex(u => new { u.TenantId, u.PhoneNumber })
            .IsUnique();

        // GIN Index على الاسم الكامل للبحث الفوري بالـ Trigrams
        builder.Entity<ApplicationUser>()
            .HasIndex(u => u.FullName)
            .HasMethod("gin")
            .HasOperators("gin_trgm_ops");
        

// تفعيل العزل (Multi-Tenancy) للجداول الجديدة (يُقيّم ديناميكياً مع كل Request)
        builder.Entity<AttendanceRecord>().HasQueryFilter(e => e.TenantId == currentTenantService.TenantId);
        builder.Entity<PaymentRecord>().HasQueryFilter(e => e.TenantId == currentTenantService.TenantId);
        
        // إعداد الـ Relations (علشان لما تمسح يوزر، تمسح حضوره ومدفوعاته أو تخليها Null حسب البيزنس بتاعك)
        // يُفضل استخدام Cascade Delete للمشتركين عشان الداتابيز تنضف
        builder.Entity<AttendanceRecord>()
            .HasOne(a => a.Member)
            .WithMany(m => m.AttendanceRecords)
            .HasForeignKey(a => a.MemberId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<PaymentRecord>()
            .HasOne(p => p.Member)
            .WithMany(m => m.PaymentRecords)
            .HasForeignKey(p => p.MemberId)
            .OnDelete(DeleteBehavior.Cascade);
        
        // Index لتسريع جلب حضور مشترك معين مترتب بالتاريخ (ده هيفيدنا جداً في شاشة بروفايل المشترك)
        builder.Entity<AttendanceRecord>()
            .HasIndex(a => new { a.MemberId, a.CheckInTime });
        
        builder.Entity<PaymentRecord>()
            .HasIndex(p => new { p.TenantId, p.OperationId })
            .IsUnique()
            .HasFilter("\"OperationId\" IS NOT NULL");

        builder.Entity<IdempotencyRecord>(b =>
        {
            b.HasKey(e => e.Id);
            b.Property(e => e.IdempotencyKey).HasMaxLength(100).IsRequired();
            b.Property(e => e.RequestPath).HasMaxLength(256).IsRequired();
            b.Property(e => e.ResponseBody).IsRequired();
            b.HasIndex(e => new { e.GymId, e.IdempotencyKey }).IsUnique();
        });
        builder.Entity<IdempotencyRecord>().HasQueryFilter(e => e.GymId.ToString() == currentTenantService.TenantId);
    }
}