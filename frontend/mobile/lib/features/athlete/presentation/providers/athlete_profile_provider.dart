import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/athlete_profile.dart';
import '../../domain/usecases/get_athlete_profile.dart';

enum AthleteProfileStatus { initial, loading, loaded, error }

class AthleteProfileProvider extends ChangeNotifier {
  AthleteProfileProvider({required GetAthleteProfile getAthleteProfile})
      : _getAthleteProfile = getAthleteProfile;

  final GetAthleteProfile _getAthleteProfile;

  AthleteProfileStatus _status = AthleteProfileStatus.initial;
  AthleteProfile? _profile;
  String? _errorMessage;

  AthleteProfileStatus get status => _status;
  AthleteProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AthleteProfileStatus.loading;

  Future<void> loadProfile() async {
    _status = AthleteProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _getAthleteProfile();
      _status = AthleteProfileStatus.loaded;
    } on ApiException catch (e) {
      _status = AthleteProfileStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = AthleteProfileStatus.error;
      _errorMessage = 'Unable to load your profile. Please try again.';
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AthleteProfileStatus.error) {
      _status = _profile != null ? AthleteProfileStatus.loaded : AthleteProfileStatus.initial;
    }
    notifyListeners();
  }
}