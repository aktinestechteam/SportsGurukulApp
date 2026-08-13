import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/academy.dart';
import '../../domain/repositories/academy_repository.dart';
import '../../domain/usecases/create_academy.dart';
import '../../domain/usecases/delete_academy.dart';
import '../../domain/usecases/get_academies.dart';
import '../../domain/usecases/get_academy.dart';
import '../../domain/usecases/update_academy.dart';

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
  }) : _createAcademy = createAcademy,
       _getAcademies = getAcademies,
       _getAcademy = getAcademy,
       _updateAcademy = updateAcademy,
       _deleteAcademy = deleteAcademy;

  final CreateAcademy _createAcademy;
  final GetAcademies _getAcademies;
  final GetAcademy _getAcademy;
  final UpdateAcademy _updateAcademy;
  final DeleteAcademy _deleteAcademy;

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
    }
  }

  Future<bool> deleteAcademy(String academyId) async {
    _status = AcademyStatus.deleting;
    _errorMessage = null;
    notifyListeners();

    try {
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
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
