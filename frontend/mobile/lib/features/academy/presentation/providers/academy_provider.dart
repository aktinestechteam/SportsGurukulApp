import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/academy.dart';
import '../../domain/repositories/academy_repository.dart';
import '../../domain/usecases/create_academy.dart';
import '../../domain/usecases/delete_academy.dart';
import '../../domain/usecases/get_academies.dart';
import '../../domain/usecases/get_academy.dart';
import '../../domain/usecases/update_academy.dart';
import '../../../batch/domain/repositories/batch_repository.dart';
import '../../../coach/domain/repositories/coach_repository.dart';
import '../../../athlete/domain/repositories/athlete_repository.dart';

enum AcademyStatus {
  initial,
  loading,
  loaded,
  saving,
  deleting,
  error,
}

class AcademyProvider extends ChangeNotifier {
  AcademyProvider({
    required CreateAcademy createAcademy,
    required GetAcademies getAcademies,
    required GetAcademy getAcademy,
    required UpdateAcademy updateAcademy,
    required DeleteAcademy deleteAcademy,
    required BatchRepository batchRepository,
    required CoachRepository coachRepository,
    required AthleteRepository athleteRepository,
  }) : _createAcademy = createAcademy,
       _getAcademies = getAcademies,
       _getAcademy = getAcademy,
       _updateAcademy = updateAcademy,
       _deleteAcademy = deleteAcademy,
       _batchRepository = batchRepository,
       _coachRepository = coachRepository,
       _athleteRepository = athleteRepository;

  final CreateAcademy _createAcademy;
  final GetAcademies _getAcademies;
  final GetAcademy _getAcademy;
  final UpdateAcademy _updateAcademy;
  final DeleteAcademy _deleteAcademy;
  final BatchRepository _batchRepository;
  final CoachRepository _coachRepository;
  final AthleteRepository _athleteRepository;

  AcademyStatus _status = AcademyStatus.initial;
  List<Academy> _academies = [];
  String? _errorMessage;

  AcademyStatus get status => _status;
  List<Academy> get academies => _academies;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AcademyStatus.loading;
  bool get isSaving => _status == AcademyStatus.saving;

  Future<void> loadAcademies() async {
    _status = AcademyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _academies = await _getAcademies();
      _status = AcademyStatus.loaded;
    } on ApiException catch (e) {
      _status = AcademyStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = AcademyStatus.error;
      _errorMessage = 'Unable to load academies. Please try again.';
    }
    notifyListeners();
  }

  Future<Academy?> loadAcademy(String academyId) async {
    _status = AcademyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final academy = await _getAcademy(academyId);
      _status = AcademyStatus.loaded;
      notifyListeners();
      return academy;
    } on ApiException catch (e) {
      _status = AcademyStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = AcademyStatus.error;
      _errorMessage = 'Unable to load the academy. Please try again.';
    }
    notifyListeners();
    return null;
  }

  Future<bool> createAcademy(AcademyRequestInput input) async {
    _status = AcademyStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final academy = await _createAcademy(input);
      _academies = [academy, ..._academies];
      _status = AcademyStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AcademyStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AcademyStatus.error;
      _errorMessage = 'Unable to register the academy. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAcademy(String academyId, AcademyRequestInput input) async {
    _status = AcademyStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final academy = await _updateAcademy(academyId, input);
      _academies = [
        for (final a in _academies)
          if (a.id == academy.id) academy else a,
      ];
      _status = AcademyStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AcademyStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AcademyStatus.error;
      _errorMessage = 'Unable to save the academy. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAcademy(String academyId) async {
    _status = AcademyStatus.deleting;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete child entities first to avoid foreign key violations.
      // Order: batches → coaches → athletes, then the academy itself.
      final batches = await _batchRepository.getBatches(academyId);
      for (final batch in batches) {
        try {
          await _batchRepository.deleteBatch(academyId, batch.batchId);
        } catch (_) {
          // Best-effort: continue even if a single batch delete fails.
        }
      }

      final coaches = await _coachRepository.getCoaches(academyId);
      for (final coach in coaches) {
        try {
          await _coachRepository.deleteCoach(academyId, coach.coachId);
        } catch (_) {}
      }

      final athletes = await _athleteRepository.getAthletes(academyId);
      for (final athlete in athletes) {
        try {
          await _athleteRepository.deleteAthlete(academyId, athlete.athleteId);
        } catch (_) {}
      }

      await _deleteAcademy(academyId);
      _academies = _academies.where((a) => a.id != academyId).toList();
      _status = AcademyStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AcademyStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AcademyStatus.error;
      _errorMessage = 'Unable to delete the academy. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
