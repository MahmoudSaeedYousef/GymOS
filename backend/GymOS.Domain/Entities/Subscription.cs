using GymOS.Domain.Common;

namespace GymOS.Domain.Entities;

public enum SubscriptionStatus
{
    Pending,
    Active,
    Frozen,
    Expired,
    Cancelled
}

public class Subscription : BaseEntity
{
    public string MemberId { get; set; } = string.Empty;
    public ApplicationUser Member { get; set; } = null!;
    
    public Guid PlanId { get; set; }
    public Plan Plan { get; set; } = null!;

    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public SubscriptionStatus Status { get; private set; } = SubscriptionStatus.Pending;
    public int? RemainingVisits { get; set; } // null للباقات بالمدة، ورقم >= 0 لباقات الزيارات

    public bool HasValidEntitlement(DateTime utcNow)
    {
        if (Status != SubscriptionStatus.Active) return false;
        if (EndDate < DateOnly.FromDateTime(utcNow)) return false;
        if (RemainingVisits.HasValue && RemainingVisits.Value <= 0) return false;
        return true;
    }

    public void ConsumeVisit()
    {
        if (!RemainingVisits.HasValue) return;
        if (RemainingVisits.Value <= 0)
            throw new InvalidOperationException("لا توجد زيارات متبقية في هذه الباقة.");

        RemainingVisits--;
        if (RemainingVisits == 0)
            Status = SubscriptionStatus.Expired;
    }
    // قواعد انتقال الحالات (State Machine Guards)
    public void Activate()
    {
        if (Status != SubscriptionStatus.Pending && Status != SubscriptionStatus.Frozen)
            throw new InvalidOperationException($"Cannot activate subscription from {Status} state.");
        
        Status = SubscriptionStatus.Active;
    }

    public void Freeze(int freezeDays)
    {
        if (Status != SubscriptionStatus.Active)
            throw new InvalidOperationException("Only active subscriptions can be frozen.");

        Status = SubscriptionStatus.Frozen;
        EndDate = EndDate.AddDays(freezeDays);
    }

    public void Cancel()
    {
        if (Status == SubscriptionStatus.Expired)
            throw new InvalidOperationException("Cannot cancel an already expired subscription.");

        Status = SubscriptionStatus.Cancelled;
    }
}