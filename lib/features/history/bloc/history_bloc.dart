import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/lease_history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

/// Manages Firestore-synced (and offline-cached) anonymized lease history.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required LeaseHistoryRepository repository,
  })  : _repository = repository,
        super(
          HistoryState(
            cloudSyncActive: repository.isCloudSyncActive,
            uid: repository.currentUid,
          ),
        ) {
    on<LoadHistoryRequested>(_onLoadHistory);
    on<SaveAnalysisToHistory>(_onSaveAnalysis);
    on<SaveDraftToHistory>(_onSaveDraft);
    on<DeleteHistoryRecord>(_onDeleteRecord);
  }

  final LeaseHistoryRepository _repository;

  Future<void> _onLoadHistory(
    LoadHistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    try {
      final records = await _repository.fetchHistory();
      emit(
        state.copyWith(
          loading: false,
          records: records,
          cloudSyncActive: _repository.isCloudSyncActive,
          uid: _repository.currentUid,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'Failed to load history: $e',
        ),
      );
    }
  }

  Future<void> _onSaveAnalysis(
    SaveAnalysisToHistory event,
    Emitter<HistoryState> emit,
  ) async {
    await _repository.saveAnalysis(event.analysis);
    final records = await _repository.fetchHistory();
    emit(state.copyWith(records: records));
  }

  Future<void> _onSaveDraft(
    SaveDraftToHistory event,
    Emitter<HistoryState> emit,
  ) async {
    await _repository.saveDraft(event.analysis, event.draft);
    final records = await _repository.fetchHistory();
    emit(state.copyWith(records: records));
  }

  Future<void> _onDeleteRecord(
    DeleteHistoryRecord event,
    Emitter<HistoryState> emit,
  ) async {
    await _repository.deleteRecord(event.leaseId);
    final records = await _repository.fetchHistory();
    emit(state.copyWith(records: records));
  }
}
