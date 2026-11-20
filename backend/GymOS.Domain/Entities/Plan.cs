using GymOS.Domain.Common;
using GymOS.Domain.Enums;

namespace GymOS.Domain.Entities;

public class Plan : BaseEntity
{
    public string Name { get; set; } = string.Empty; // مثلاً: باقة شهرية، 3 شهور
    public decimal Price { get; set; } // دايماً decimal للفلوس، ممنوع float/double
    public int DurationInDays { get; set; }
    public int? MaxSessions { get; set; } // null لو مفتوح، أو رقم لو باقة حصص
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }
    public PlanKind Kind { get; set; } = PlanKind.Duration;
    public int? VisitsIncluded { get; set; }
}