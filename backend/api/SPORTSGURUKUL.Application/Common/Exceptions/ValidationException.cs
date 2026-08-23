namespace SPORTSGURUKUL.Application.Common.Exceptions;

public class ValidationException : Exception
{
    public IDictionary<string, string[]> Errors { get; }

    public ValidationException(IDictionary<string, string[]> errors)
        : base("Validation failed.")
    {
        Errors = errors;
    }

    public ValidationException(string property, string message)
        : this(new Dictionary<string, string[]> { [property] = [message] })
    {
    }
}
