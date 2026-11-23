import 'package:equatable/equatable.dart';

import '../data/lease_history_repository.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.loading = false,
    this.records = const [],
    this.cloudSyncActive = false,
    this.uid,
    this.errorMessage,
  });

  final bool loading;
  final List<SavedLeaseRecord> records;
  final bool cloudSyncActive;
  final String? uid;
  final String? errorMessage;

  HistoryState copyWith({
    bool? loading,
    List<SavedLeaseRecord>? records,
    bool? cloudSyncActive,
    String? uid,
    String? errorMessage,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      records: records ?? this.records,
      cloudSyncActive: cloudSyncActive ?? this.cloudSyncActive,
      uid: uid ?? this.uid,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        records,
        cloudSyncActive,
        uid,
        errorMessage,
      ];
}
