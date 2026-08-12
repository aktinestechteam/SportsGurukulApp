using SPORTSGURUKUL.Application.Common;
using SPORTSGURUKUL.Application.Common.Exceptions;

namespace SPORTSGURUKUL.Api.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (AppException ex)
        {
            _logger.LogWarning("AppException ({StatusCode}): {Message}", ex.StatusCode, ex.Message);
            await WriteJsonAsync(context, ex.StatusCode, ApiResponse<object>.Fail(ex.Message));
        }
        catch (ValidationException ex)
        {
            var details = string.Join("; ", ex.Errors.Select(kv => $"{kv.Key}: {string.Join(", ", kv.Value)}"));
            _logger.LogWarning("Validation failed: {Errors}", details);
            await WriteJsonAsync(context, StatusCodes.Status400BadRequest,
                ApiResponse<object>.Fail("Validation failed.", ex.Errors));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception");
            await WriteJsonAsync(context, StatusCodes.Status500InternalServerError,
                ApiResponse<object>.Fail("An unexpected error occurred. Please try again later."));
        }
    }

    private static async Task WriteJsonAsync(HttpContext context, int statusCode, ApiResponse<object> response)
    {
        context.Response.Clear();
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json; charset=utf-8";
        await context.Response.WriteAsJsonAsync(response);
    }
}
