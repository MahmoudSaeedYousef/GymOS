using MediatR;
using Microsoft.EntityFrameworkCore;
using GymOS.Application.Interfaces;
using GymOS.Domain.Enums;

namespace GymOS.Application.Features.Payments.Queries.GetPayments;

public record PaymentItemDto(
    Guid Id,
    string MemberName,
    string MemberPhone,
    string PlanName,
    decimal Amount,
    PaymentMethod Method,
    DateTime PaymentDate,
    string? Notes
);

public record PaymentsSummaryDto(
    decimal TotalAmount,
    decimal CashTotal,
    decimal InstaPayTotal,
    decimal VodafoneCashTotal,
    decimal VisaTotal,
    List<PaymentItemDto> Items
);

public record GetPaymentsQuery(string Period = "month") : IRequest<PaymentsSummaryDto>;

public class GetPaymentsQueryHandler(IGymDbContext context)
    : IRequestHandler<GetPaymentsQuery, PaymentsSummaryDto>
{
    public async Task<PaymentsSummaryDto> Handle(GetPaymentsQuery request, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var today = now.Date;
        var tomorrow = today.AddDays(1);
        var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var query = context.PaymentRecords.AsQueryable();

        query = request.Period.ToLower() switch
        {
            "today" => query.Where(p => p.PaymentDate >= today && p.PaymentDate < tomorrow),
            "month" => query.Where(p => p.PaymentDate >= startOfMonth),
            _ => query
        };

        var payments = await query
            .OrderByDescending(p => p.PaymentDate)
            .Select(p => new PaymentItemDto(
                p.Id,
                p.Member != null ? p.Member.FullName : (p.Notes ?? "Guest"),
                p.Member != null ? (p.Member.PhoneNumber ?? string.Empty) : string.Empty,
                p.Plan != null ? p.Plan.Name : (p.IsDropIn ? "حصة منفردة" : string.Empty),
                p.Amount,
                p.Method,
                p.PaymentDate,
                p.Notes
            ))
            .ToListAsync(cancellationToken);

        return new PaymentsSummaryDto(
            TotalAmount: payments.Sum(p => p.Amount),
            CashTotal: payments.Where(p => p.Method == PaymentMethod.Cash).Sum(p => p.Amount),
            InstaPayTotal: payments.Where(p => p.Method == PaymentMethod.InstaPay).Sum(p => p.Amount),
            VodafoneCashTotal: payments.Where(p => p.Method == PaymentMethod.VodafoneCash).Sum(p => p.Amount),
            VisaTotal: payments.Where(p => p.Method == PaymentMethod.Visa).Sum(p => p.Amount),
            Items: payments
        );
    }
}