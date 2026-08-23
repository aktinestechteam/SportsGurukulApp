import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../../domain/usecases/create_athlete.dart';
import '../../domain/usecases/delete_athlete.dart';
import '../../domain/usecases/get_athletes.dart';
import '../../domain/usecases/update_athlete.dart';

enum AthleteLoadStatus { initial, loading, loaded, saving, deleting, error }

class AthleteProvider extends ChangeNotifier {
  AthleteProvider({
    required CreateAthlete createAthlete,
    required GetAthletes getAthletes,
    required UpdateAthlete updateAthlete,
    required DeleteAthlete deleteAthlete,
  }) : _createAthlete = createAthlete,
       _getAthletes = getAthletes,
       _updateAthlete = updateAthlete,
       _deleteAthlete = deleteAthlete;

  final CreateAthlete _createAthlete;
  final GetAthletes _getAthletes;
  final UpdateAthlete _updateAthlete;
  final DeleteAthlete _deleteAthlete;

  AthleteLoadStatus _status = AthleteLoadStatus.initial;
  List<Athlete> _athletes = [];
  String? _errorMessage;

  AthleteLoadStatus get status => _status;
  List<Athlete> get athletes => _athletes;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AthleteLoadStatus.loading;
  bool get isSaving => _status == AthleteLoadStatus.saving;
  bool get isDeleting => _status == AthleteLoadStatus.deleting;

  Future<void> loadAthletes(String academyId) async {
    _status = AthleteLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _athletes = await _getAthletes(academyId);
      _status = AthleteLoadStatus.loaded;
    } on ApiException catch (e) {
      _status = AthleteLoadStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = AthleteLoadStatus.error;
      _errorMessage = 'Unable to load athletes. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> createAthlete(String academyId, AthleteRequestInput input) async {
    _status = AthleteLoadStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final athlete = await _createAthlete(academyId, input);
      _athletes = [athlete, ..._athletes];
      _status = AthleteLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AthleteLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AthleteLoadStatus.error;
      _errorMessage = 'Unable to add the athlete. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAthlete(
    String academyId,
    String athleteId,
    AthleteRequestInput input,
  ) async {
    _status = AthleteLoadStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final athlete = await _updateAthlete(academyId, athleteId, input);
      _athletes = [
        for (final a in _athletes)
          if (a.athleteId == athlete.athleteId) athlete else a,
      ];
      _status = AthleteLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AthleteLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AthleteLoadStatus.error;
      _errorMessage = 'Unable to save the athlete. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAthlete(String academyId, String athleteId) async {
    _status = AthleteLoadStatus.deleting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteAthlete(academyId, athleteId);
      _athletes = _athletes.where((a) => a.athleteId != athleteId).toList();
      _status = AthleteLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AthleteLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AthleteLoadStatus.error;
      _errorMessage = 'Unable to remove the athlete. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
