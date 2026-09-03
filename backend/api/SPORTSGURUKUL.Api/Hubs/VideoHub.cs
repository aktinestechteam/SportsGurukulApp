using System.Collections.Concurrent;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SPORTSGURUKUL.Api.Hubs;

/// <summary>
/// Real-time hub for the video feature. Tracks each authenticated user's
/// connections so the server can target specific users, and groups clients
/// per video so comment events reach everyone watching that video.
/// </summary>
[Authorize]
public class VideoHub : Hub
{
    private static readonly ConcurrentDictionary<Guid, HashSet<string>> _connections = new();

    public override async Task OnConnectedAsync()
    {
        var userId = GetUserId();
        if (userId != Guid.Empty)
        {
            _connections.AddOrUpdate(
                userId,
                _ => new HashSet<string> { Context.ConnectionId },
                (_, set) =>
                {
                    lock (set)
                    {
                        set.Add(Context.ConnectionId);
                    }
                    return set;
                });
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        if (userId != Guid.Empty && _connections.TryGetValue(userId, out var set))
        {
            lock (set)
            {
                set.Remove(Context.ConnectionId);
                if (set.Count == 0)
                {
                    _connections.TryRemove(userId, out _);
                }
            }
        }

        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Adds the current connection to the group for a specific video so it can
    /// receive comment events for that video.
    /// </summary>
    public Task JoinVideo(Guid videoId)
        => Groups.AddToGroupAsync(Context.ConnectionId, GroupName(videoId));

    /// <summary>
    /// Removes the current connection from the group for a specific video.
    /// </summary>
    public Task LeaveVideo(Guid videoId)
        => Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(videoId));

    internal static string GroupName(Guid videoId) => $"video-{videoId}";

    /// <summary>
    /// Returns the current connection ids for a user across all of their
    /// devices, or an empty collection when the user has no active connections.
    /// </summary>
    internal static IReadOnlyList<string> GetConnections(Guid userId)
    {
        if (!_connections.TryGetValue(userId, out var set))
        {
            return Array.Empty<string>();
        }

        lock (set)
        {
            return set.ToArray();
        }
    }

    private Guid GetUserId()
        => Guid.TryParse(
            Context.User?.FindFirstValue(ClaimTypes.NameIdentifier),
            out var id)
            ? id
            : Guid.Empty;
}
