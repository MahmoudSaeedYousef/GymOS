using GymOS.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace GymOS.Application.Interfaces;

public interface IGymDbContext
{
    DbSet<GymTenant> Tenants { get; }
    DbSet<Plan> Plans { get; }
    DbSet<Subscription> Subscriptions { get; }
    DbSet<ApplicationUser> Users { get; }
    DbSet<AttendanceRecord> AttendanceRecords { get; }
    DbSet<PaymentRecord> PaymentRecords { get;}
    DbSet<IdempotencyRecord> IdempotencyRecords { get; }
    DatabaseFacade Database { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}