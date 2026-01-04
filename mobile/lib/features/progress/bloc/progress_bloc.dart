import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import '../../../core/models/data_models.dart';
import '../../../core/repositories/data_repository.dart';

// EVENTS
abstract class ProgressEvent extends Equatable {
  const ProgressEvent();
  @override
  List<Object?> get props => [];
}

class LoadProgressData extends ProgressEvent {
  final int days;
  const LoadProgressData({this.days = 7});
  @override
  List<Object?> get props => [days];
}

class AddWeightLog extends ProgressEvent {
  final double weight;
  const AddWeightLog(this.weight);
  @override
  List<Object?> get props => [weight];
}

// STATE
class ProgressState extends Equatable {
  final List<FoodLog> history;
  final List<Map<String, dynamic>> weightHistory;
  final bool isLoading;
  final String? errorMessage;
  final int selectedDays;

  const ProgressState({
    this.history = const [],
    this.weightHistory = const [],
    this.isLoading = true,
    this.errorMessage,
    this.selectedDays = 7,
  });

  Map<DateTime, int> get dailyCalories {
    final Map<DateTime, int> data = {};
    for (var log in history) {
      final date = DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day);
      data[date] = (data[date] ?? 0) + log.calories;
    }
    return data;
  }

  ProgressState copyWith({
    List<FoodLog>? history,
    List<Map<String, dynamic>>? weightHistory,
    bool? isLoading,
    String? errorMessage,
    int? selectedDays,
  }) {
    return ProgressState(
      history: history ?? this.history,
      weightHistory: weightHistory ?? this.weightHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }

  @override
  List<Object?> get props => [history, weightHistory, isLoading, errorMessage, selectedDays];
}

// BLOC
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final DataRepository _repository;
  StreamSubscription? _dataSubscription;

  ProgressBloc(this._repository) : super(const ProgressState()) {
    on<LoadProgressData>(_onLoadProgress);
    on<AddWeightLog>(_onAddWeightLog);
    on<_DataUpdatedInternal>(_onDataUpdated);
  }

  Future<void> _onLoadProgress(LoadProgressData event, Emitter<ProgressState> emit) async {
    emit(state.copyWith(isLoading: true, selectedDays: event.days));
    
    _dataSubscription?.cancel();
    _dataSubscription = CombineLatestStream.combine2(
      _repository.todayLogsStream,
      _repository.weightHistoryStream,
      (logs, weight) => _DataUpdatedInternal(logs, weight),
    ).listen((event) => add(event));

    // Force a fresh fetch for weight history for the specified days
    await _repository.getWeightHistory(event.days);
  }

  void _onDataUpdated(_DataUpdatedInternal event, Emitter<ProgressState> emit) {
    emit(state.copyWith(
      history: event.logs,
      weightHistory: event.weight,
      isLoading: false,
    ));
  }

  Future<void> _onAddWeightLog(AddWeightLog event, Emitter<ProgressState> emit) async {
    // Optimistic Update
    final newLog = {
      'weight': event.weight,
      'created_at': DateTime.now().toIso8601String(),
    };
    final updatedHistory = List<Map<String, dynamic>>.from(state.weightHistory)..add(newLog);
    updatedHistory.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
    emit(state.copyWith(weightHistory: updatedHistory));

    try {
      await _repository.addWeightEntry(event.weight);
    } catch (e) {
      debugPrint('ProgressBloc: Error adding weight: $e');
      add(LoadProgressData(days: state.selectedDays));
    }
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }
}

class _DataUpdatedInternal extends ProgressEvent {
  final List<FoodLog> logs;
  final List<Map<String, dynamic>> weight;
  const _DataUpdatedInternal(this.logs, this.weight);
  @override
  List<Object?> get props => [logs, weight];
}
