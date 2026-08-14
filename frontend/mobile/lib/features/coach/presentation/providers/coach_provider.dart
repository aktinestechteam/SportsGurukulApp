import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/coach.dart';
import '../../domain/repositories/coach_repository.dart';
import '../../domain/usecases/create_coach.dart';
import '../../domain/usecases/delete_coach.dart';
import '../../domain/usecases/get_coaches.dart';
import '../../domain/usecases/update_coach.dart';

enum CoachLoadStatus { initial, loading, loaded, saving, deleting, error }

class CoachProvider extends ChangeNotifier {
  CoachProvider({
    required CreateCoach createCoach,
    required GetCoaches getCoaches,
    required UpdateCoach updateCoach,
    required DeleteCoach deleteCoach,
  }) : _createCoach = createCoach,
       _getCoaches = getCoaches,
       _updateCoach = updateCoach,
       _deleteCoach = deleteCoach;

  final CreateCoach _createCoach;
  final GetCoaches _getCoaches;
  final UpdateCoach _updateCoach;
  final DeleteCoach _deleteCoach;

  CoachLoadStatus _status = CoachLoadStatus.initial;
  List<Coach> _coaches = [];
  String? _errorMessage;

  CoachLoadStatus get status => _status;
  List<Coach> get coaches => _coaches;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CoachLoadStatus.loading;
  bool get isSaving => _status == CoachLoadStatus.saving;
  bool get isDeleting => _status == CoachLoadStatus.deleting;

  Future<void> loadCoaches(String academyId) async {
    _status = CoachLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _coaches = await _getCoaches(academyId);
      _status = CoachLoadStatus.loaded;
    } on ApiException catch (e) {
      _status = CoachLoadStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = CoachLoadStatus.error;
      _errorMessage = 'Unable to load coaches. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> createCoach(String academyId, CoachRequestInput input) async {
    _status = CoachLoadStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final coach = await _createCoach(academyId, input);
      _coaches = [coach, ..._coaches];
      _status = CoachLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = CoachLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = CoachLoadStatus.error;
      _errorMessage = 'Unable to add the coach. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCoach(
    String academyId,
    String coachId,
    CoachRequestInput input,
  ) async {
    _status = CoachLoadStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final coach = await _updateCoach(academyId, coachId, input);
      _coaches = [
        for (final c in _coaches) if (c.coachId == coach.coachId) coach else c,
      ];
      _status = CoachLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = CoachLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = CoachLoadStatus.error;
      _errorMessage = 'Unable to save the coach. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCoach(String academyId, String coachId) async {
    _status = CoachLoadStatus.deleting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteCoach(academyId, coachId);
      _coaches = _coaches.where((c) => c.coachId != coachId).toList();
      _status = CoachLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = CoachLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = CoachLoadStatus.error;
      _errorMessage = 'Unable to remove the coach. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
