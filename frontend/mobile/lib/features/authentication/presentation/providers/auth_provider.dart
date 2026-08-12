import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/check_session.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/refresh_session.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';

enum AuthStatus {
  initial,
  checkingSession,
  unauthenticated,
  authenticating,
  authenticated,
  refreshing,
  loggingOut,
  sessionExpired,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required RefreshSession refreshSession,
    required GetCurrentUser getCurrentUser,
    required CheckSession checkSession,
    required ForgotPassword forgotPassword,
    required ResetPassword resetPassword,
    required ChangePassword changePassword,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _refreshSession = refreshSession,
       _getCurrentUser = getCurrentUser,
       _checkSession = checkSession,
       _forgotPassword = forgotPassword,
       _resetPassword = resetPassword,
       _changePassword = changePassword;

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final RefreshSession _refreshSession;
  final GetCurrentUser _getCurrentUser;
  final CheckSession _checkSession;
  final ForgotPassword _forgotPassword;
  final ResetPassword _resetPassword;
  final ChangePassword _changePassword;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _handlingExpiry = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    _status = AuthStatus.checkingSession;
    _errorMessage = null;
    notifyListeners();

    var hasSession = false;
    try {
      hasSession = await _checkSession();
    } catch (_) {
      hasSession = false;
    }

    if (!hasSession) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final session = await _refreshSession();
      final user = await _getCurrentUser();
      _user = user.id.isNotEmpty ? user : session.user;
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.sessionExpired;
      _user = null;
      try {
        await _signOut();
      } catch (_) {
        // Local cleanup already handles the session; failure here must not
        // block navigation back to the sign-in screen.
      }
    }
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _signIn(email: email.trim(), password: password);
      _user = session.user;
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.friendlyMessage;
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _signUp(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        mobileNumber: mobileNumber.trim(),
        password: password,
        confirmPassword: confirmPassword,
        acceptTerms: acceptTerms,
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loggingOut;
    notifyListeners();

    try {
      await _signOut();
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> handleSessionExpired() async {
    if (_handlingExpiry ||
        _status == AuthStatus.unauthenticated ||
        _status == AuthStatus.sessionExpired ||
        _status == AuthStatus.loggingOut) {
      return;
    }
    _handlingExpiry = true;
    try {
      _user = null;
      _status = AuthStatus.sessionExpired;
      notifyListeners();

      await _signOut();

      if (_status == AuthStatus.sessionExpired) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } finally {
      _handlingExpiry = false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _forgotPassword(email.trim());
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    }
  }

  /// Returns true when the password was changed and the local session cleared.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
