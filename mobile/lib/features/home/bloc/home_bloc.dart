import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import '../../../core/models/data_models.dart';
import '../../../core/repositories/data_repository.dart';

// EVENTS
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class SubscribeToHomeData extends HomeEvent {}
class DataUpdated extends HomeEvent {
  final List<FoodLog> foodLogs;
  final List<WaterLog> waterLogs;
  final UserProfile profile;
  const DataUpdated(this.foodLogs, this.waterLogs, this.profile);
  @override
  List<Object?> get props => [foodLogs, waterLogs, profile];
}
class AddWaterRequested extends HomeEvent {
  final int amount;
  const AddWaterRequested(this.amount);
}
class AddFoodRequested extends HomeEvent {
  final String name;
  final int calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final List<dynamic>? ingredients;
  const AddFoodRequested({required this.name, required this.calories, this.protein, this.carbs, this.fat, this.ingredients});
}

// STATE
class HomeState extends Equatable {
  final List<FoodLog> foodLogs;
  final List<WaterLog> waterLogs;
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.foodLogs = const [],
    this.waterLogs = const [],
    this.profile,
    this.isLoading = true,
    this.errorMessage,
  });

  int get totalCalories => foodLogs.fold(0, (sum, item) => sum + item.calories);
  int get totalProtein => foodLogs.fold(0, (sum, item) => sum + (item.protein ?? 0));
  int get totalCarbs => foodLogs.fold(0, (sum, item) => sum + (item.carbs ?? 0));
  int get totalFat => foodLogs.fold(0, (sum, item) => sum + (item.fat ?? 0));
  int get totalWater => waterLogs.fold(0, (sum, item) => sum + item.amountMl);

  HomeState copyWith({
    List<FoodLog>? foodLogs,
    List<WaterLog>? waterLogs,
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      foodLogs: foodLogs ?? this.foodLogs,
      waterLogs: waterLogs ?? this.waterLogs,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [foodLogs, waterLogs, profile, isLoading, errorMessage];
}

// BLOC

// BLOC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DataRepository _repository;
  StreamSubscription? _dataSubscription;

  HomeBloc(this._repository) : super(const HomeState()) {
    on<SubscribeToHomeData>(_onSubscribe);
    on<DataUpdated>(_onDataUpdated);
    on<AddWaterRequested>(_onAddWater);
    on<AddFoodRequested>(_onAddFood);
  }

  Future<void> _onSubscribe(SubscribeToHomeData event, Emitter<HomeState> emit) async {
    _dataSubscription?.cancel();
    _dataSubscription = CombineLatestStream.combine3(
      _repository.profileStream,
      _repository.todayLogsStream,
      _repository.waterLogsStream,
      (profile, food, water) => DataUpdated(food, water, profile ?? UserProfile(id: 'unknown')),
    ).listen((event) => add(event));
  }

  void _onDataUpdated(DataUpdated event, Emitter<HomeState> emit) {
    // Standardize: Filter for "today" only if repository doesn't already
    final now = DateTime.now();
    final todayFood = event.foodLogs.where((l) => 
      l.createdAt.year == now.year && 
      l.createdAt.month == now.month && 
      l.createdAt.day == now.day
    ).toList();
    
    final todayWater = event.waterLogs.where((l) => 
      l.createdAt.year == now.year && 
      l.createdAt.month == now.month && 
      l.createdAt.day == now.day
    ).toList();

    emit(state.copyWith(
      foodLogs: todayFood,
      waterLogs: todayWater,
      profile: event.profile,
      isLoading: false,
    ));
  }

  Future<void> _onAddWater(AddWaterRequested event, Emitter<HomeState> emit) async {
    // Optimistic Logic moved to Repository or kept here?
    // Let's keep optimistic here for "snappy" UI, but simplified
    final tempLog = WaterLog(
      id: 'temp_${DateTime.now().ms}',
      userId: 'user',
      amountMl: event.amount,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(waterLogs: [...state.waterLogs, tempLog]));
    
    try {
      await _repository.addWaterLog(event.amount);
    } catch (e) {
      debugPrint('HomeBloc: Error adding water: $e');
      add(SubscribeToHomeData()); // Forced resync on error
    }
  }

  Future<void> _onAddFood(AddFoodRequested event, Emitter<HomeState> emit) async {
    final tempLog = FoodLog(
      id: 'temp_${DateTime.now().ms}',
      userId: 'user',
      foodName: event.name,
      calories: event.calories,
      protein: event.protein,
      carbs: event.carbs,
      fat: event.fat,
      ingredients: event.ingredients,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(foodLogs: [...state.foodLogs, tempLog]));

    try {
      await _repository.addFoodLog(
        name: event.name,
        calories: event.calories,
        protein: event.protein,
        carbs: event.carbs,
        fat: event.fat,
        ingredients: event.ingredients,
      );
    } catch (e) {
      debugPrint('HomeBloc: Error adding food: $e');
      add(SubscribeToHomeData());
    }
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }
}

extension on DateTime {
  int get ms => millisecondsSinceEpoch;
}
