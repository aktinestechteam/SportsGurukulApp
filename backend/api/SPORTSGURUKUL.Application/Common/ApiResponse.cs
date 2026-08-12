namespace SPORTSGURUKUL.Application.Common;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public IDictionary<string, string[]>? Errors { get; set; }

    public static ApiResponse<T> Ok(T data, string message = "Operation completed successfully.")
        => new() { Success = true, Message = message, Data = data };

    public static ApiResponse<T> OkNoData(string message = "Operation completed successfully.")
        => new() { Success = true, Message = message };

    public static ApiResponse<T> Fail(string message, IDictionary<string, string[]>? errors = null)
        => new() { Success = false, Message = message, Errors = errors };
}
