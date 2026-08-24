import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/batch.dart';
import '../../domain/repositories/batch_repository.dart';
import '../../domain/usecases/create_batch.dart';
import '../../domain/usecases/delete_batch.dart';
import '../../domain/usecases/get_batch.dart';
import '../../domain/usecases/get_batches.dart';
import '../../domain/usecases/update_batch.dart';

enum BatchLoadStatus { initial, loading, loaded, saving, deleting, error }

class BatchProvider extends ChangeNotifier {
  BatchProvider({
    required CreateBatch createBatch,
    required GetBatches getBatches,
    required GetBatch getBatch,
    required UpdateBatch updateBatch,
    required DeleteBatch deleteBatch,
  }) : _createBatch = createBatch,
       _getBatches = getBatches,
       _getBatch = getBatch,
       _updateBatch = updateBatch,
       _deleteBatch = deleteBatch;

  final CreateBatch _createBatch;
  final GetBatches _getBatches;
  final GetBatch _getBatch;
  final UpdateBatch _updateBatch;
  final DeleteBatch _deleteBatch;

  BatchLoadStatus _status = BatchLoadStatus.initial;
  List<Batch> _batches = [];
  Batch? _selectedBatch;
  String? _errorMessage;

  BatchLoadStatus get status => _status;
  List<Batch> get batches => _batches;
  Batch? get selectedBatch => _selectedBatch;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == BatchLoadStatus.loading;
  bool get isSaving => _status == BatchLoadStatus.saving;
  bool get isDeleting => _status == BatchLoadStatus.deleting;

  Future<void> loadBatches(String academyId) async {
    _status = BatchLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _batches = await _getBatches(academyId);
      _status = BatchLoadStatus.loaded;
    } on ApiException catch (e) {
      _status = BatchLoadStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = BatchLoadStatus.error;
      _errorMessage = 'Unable to load batches. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> loadBatch(String academyId, String batchId) async {
    _status = BatchLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedBatch = await _getBatch(academyId, batchId);
      _status = BatchLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = BatchLoadStatus.error;
      _errorMessage = e.friendlyMessage;
    } catch (_) {
      _status = BatchLoadStatus.error;
      _errorMessage = 'Unable to load batch details. Please try again.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> createBatch(String academyId, BatchRequestInput input) async {
    _status = BatchLoadStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = await _createBatch(academyId, input);
      _batches = [batch, ..._batches];
      _status = BatchLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = BatchLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = BatchLoadStatus.error;
      _errorMessage = 'Unable to create the batch. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBatch(
    String academyId,
    String batchId,
    BatchRequestInput input,
  ) async {
    _status = BatchLoadStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = await _updateBatch(academyId, batchId, input);
      _batches = [
        for (final b in _batches) if (b.batchId == batch.batchId) batch else b,
      ];
      _selectedBatch = batch;
      _status = BatchLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = BatchLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = BatchLoadStatus.error;
      _errorMessage = 'Unable to update the batch. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBatch(String academyId, String batchId) async {
    _status = BatchLoadStatus.deleting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteBatch(academyId, batchId);
      _batches = _batches.where((b) => b.batchId != batchId).toList();
      _status = BatchLoadStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = BatchLoadStatus.error;
      _errorMessage = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _status = BatchLoadStatus.error;
      _errorMessage = 'Unable to delete the batch. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
