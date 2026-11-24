namespace GymOS.Application.Exceptions;

/// <summary>
/// Thrown by Application layer handlers when request data fails validation.
/// Carries a per-field error dictionary for structured 400 responses.
/// </summary>
public sealed class ValidationException : Exception
{
    public IReadOnlyDictionary<string, string[]> Errors { get; }

    public ValidationException(string message, IReadOnlyDictionary<string, string[]>? errors = null)
        : base(message)
    {
        Errors = errors ?? new Dictionary<string, string[]>();
    }

    public ValidationException(IReadOnlyDictionary<string, string[]> errors)
        : base("بيانات غير صحيحة. يرجى مراجعة الحقول المدخلة.")
    {
        Errors = errors;
    }
}
