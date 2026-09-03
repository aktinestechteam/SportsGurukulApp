import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/video/data/datasources/video_signalr_service.dart';

/// Drives the [VideoSignalRService] lifecycle from the [AuthProvider] state.
///
/// Connects the real-time video hub once the user is authenticated and
/// disconnects on any transition away from the authenticated state (logout,
/// session expiry, password change, etc.), so the SignalR stream subscriptions
/// held by the VideoProvider only receive pushes while a session is active.
///
/// This avoids scattering connect/disconnect calls across the auth flow.
class VideoRealtimeSession {
  VideoRealtimeSession({
    required AuthProvider authProvider,
    required VideoSignalRService signalR,
  }) : _authProvider = authProvider,
       _signalR = signalR {
    _authProvider.addListener(_onAuthChanged);
    if (_authProvider.isAuthenticated) {
      _connect();
    }
  }

  final AuthProvider _authProvider;
  final VideoSignalRService _signalR;

  Future<void> _connect() async {
    try {
      await _signalR.connect();
    } catch (_) {
      // Non-fatal: real-time updates simply won't be delivered.
    }
  }

  Future<void> _disconnect() async {
    try {
      await _signalR.disconnect();
    } catch (_) {
      // Best-effort disconnect.
    }
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      _connect();
    } else if (_signalR.isConnected) {
      _disconnect();
    }
  }

  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _disconnect();
  }
}
