import 'package:equatable/equatable.dart';

import '../domain/lease_analysis_models.dart';

sealed class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object?> get props => [];
}

final class AnalysisInitial extends AnalysisState {
  const AnalysisInitial();
}

final class AnalysisLoading extends AnalysisState {
  const AnalysisLoading({required this.statusMessage});

  final String statusMessage;

  @override
  List<Object?> get props => [statusMessage];
}

final class AnalysisSuccess extends AnalysisState {
  const AnalysisSuccess(this.result);

  final LeaseAnalysisResult result;

  @override
  List<Object?> get props => [result];
}

final class AnalysisFailure extends AnalysisState {
  const AnalysisFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
