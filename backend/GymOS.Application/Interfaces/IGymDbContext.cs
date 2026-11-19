using GymOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GymOS.Application.Interfaces;

public interface IGymDbContext
{
    DbSet<GymTenant> Tenants { get; }
    DbSet<Plan> Plans { get; }
    DbSet<Subscription> Subscriptions { get; }
    DbSet<ApplicationUser> Users { get; }
    DbSet<AttendanceRecord> AttendanceRecords { get; }
    DbSet<PaymentRecord> PaymentRecords { get;}
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}