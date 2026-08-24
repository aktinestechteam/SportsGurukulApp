import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/coach_profile.dart';
import '../../domain/usecases/get_coach_profile.dart';

enum CoachProfileStatus { initial, loading, loaded, error }

class CoachProfileProvider extends ChangeNotifier {
  CoachProfileProvider({required GetCoachProfile getCoachProfile})
      : _getCoachProfile = getCoachProfile;

  final GetCoachProfile _getCoachProfile;

  CoachProfileStatus _status = CoachProfileStatus.initial;
  CoachProfile? _profile;
  String? _errorMessage;

  CoachProfileStatus get status => _status;
  CoachProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CoachProfileStatus.loading;

  Future<void> loadProfile() async {
    _status = CoachProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _getCoachProfile();
      _status = CoachProfileStatus.loaded;
    } on ApiException catch (e) {
      _status = CoachProfileStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = CoachProfileStatus.error;
      _errorMessage = 'Unable to load your profile. Please try again.';
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == CoachProfileStatus.error) {
      _status = _profile != null ? CoachProfileStatus.loaded : CoachProfileStatus.initial;
    }
    notifyListeners();
  }
}
