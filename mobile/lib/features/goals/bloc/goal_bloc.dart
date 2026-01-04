import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:caloric_mobile/core/models/data_models.dart';
import 'package:caloric_mobile/core/repositories/data_repository.dart';

// MODELS
enum GoalType { slim, fit, cut, bodybuilding, healthy, custom }
// Gender and ActivityLevel moved to data_models.dart

class Goal {
  final GoalType type;
  final String title;
  final String description;

  const Goal({
    required this.type,
    required this.title,
    required this.description,
  });

  static const List<Goal> presets = [
    Goal(type: GoalType.slim, title: 'SLIM', description: 'Lose weight & tone up'),
    Goal(type: GoalType.fit, title: 'FIT', description: 'Maintain & stay healthy'),
    Goal(type: GoalType.cut, title: 'CUT', description: 'Lose fat, keep muscle'),
    Goal(type: GoalType.bodybuilding, title: 'BODYBUILDING', description: 'Maximum muscle gain'),
    Goal(type: GoalType.healthy, title: 'HEALTHY', description: 'Better nutrition habits'),
  ];
}

// STATE
class GoalState extends Equatable {
  final GoalType? selectedGoal;
  final Gender? gender;
  final double weight; // kg
  final double height; // cm
  final int age;
  final ActivityLevel activityLevel;
  final bool isLoading;
  final bool isOnboardingCompleted;

  const GoalState({
    this.selectedGoal,
    this.gender,
    this.weight = 70.0,
    this.height = 170.0,
    this.age = 25,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.isLoading = true,
    this.isOnboardingCompleted = false,
  });

  GoalState copyWith({
    GoalType? selectedGoal,
    Gender? gender,
    double? weight,
    double? height,
    int? age,
    ActivityLevel? activityLevel,
    bool? isLoading,
    bool? isOnboardingCompleted,
  }) {
    return GoalState(
      selectedGoal: selectedGoal ?? this.selectedGoal,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      activityLevel: activityLevel ?? this.activityLevel,
      isLoading: isLoading ?? this.isLoading,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }

  double get calorieTarget {
    if (gender == null) return 2000;
    
    // Mifflin-St Jeor Equation
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr = gender == Gender.male ? bmr + 5 : bmr - 161;

    // Activity Multiplier
    double multiplier = 1.2;
    switch (activityLevel) {
      case ActivityLevel.sedentary: multiplier = 1.2; break;
      case ActivityLevel.lightlyActive: multiplier = 1.375; break;
      case ActivityLevel.moderatelyActive: multiplier = 1.55; break;
      case ActivityLevel.veryActive: multiplier = 1.725; break;
      case ActivityLevel.extraActive: multiplier = 1.9; break;
    }

    double tdee = bmr * multiplier;

    // Apply Goal Adjustment
    switch (selectedGoal) {
      case GoalType.slim: return tdee - 500;
      case GoalType.cut: return tdee - 300;
      case GoalType.fit: return tdee;
      case GoalType.healthy: return tdee;
      case GoalType.bodybuilding: return tdee + 500;
      default: return tdee;
    }
  }

  double get idealWeight {
    if (gender == null || height <= 0) return 70.0;
    
    // Devine Formula (1974)
    // Male: 50kg + 2.3kg/inch over 5ft
    // Female: 45.5kg + 2.3kg/inch over 5ft
    // 5ft = 152.4 cm. 1 inch = 2.54 cm. 2.3/2.54 = ~0.9055 kg/cm
    
    double base = gender == Gender.male ? 50.0 : 45.5;
    double adjustment = 0.9055 * (height - 152.4);
    
    return base + adjustment;
  }

  @override
  List<Object?> get props => [selectedGoal, gender, weight, height, age, activityLevel, isLoading, isOnboardingCompleted];
}

// EVENTS
abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

class LoadGoal extends GoalEvent {}
class SetGoal extends GoalEvent {
  final GoalType goalType;
  const SetGoal(this.goalType);
  @override
  List<Object?> get props => [goalType];
}
class UpdateProfile extends GoalEvent {
  final String? fullName;
  final Gender? gender;
  final double? weight;
  final double? height;
  final int? age;
  final ActivityLevel? activityLevel;
  const UpdateProfile({this.fullName, this.gender, this.weight, this.height, this.age, this.activityLevel});
}

class UpdateTargetWeight extends GoalEvent {
  final double targetWeight;
  const UpdateTargetWeight(this.targetWeight);
  @override
  List<Object?> get props => [targetWeight];
}

class CompleteOnboarding extends GoalEvent {}

// BLOC
// BLOC
class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final DataRepository _repository;
  final SharedPreferences _prefs;
  StreamSubscription? _profileSubscription;

  GoalBloc(this._repository, this._prefs) : super(const GoalState()) {
    on<LoadGoal>(_onLoadGoal);
    on<SetGoal>(_onSetGoal);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateTargetWeight>(_onUpdateTargetWeight);
    on<CompleteOnboarding>(_onCompleteOnboarding);

    // Reactive Interlinking: Listen to repository for profile changes
    _profileSubscription = _repository.profileStream.listen((profile) {
      if (profile != null) {
        add(_ProfileUpdatedInternal(profile));
      } else {
        add(const _ProfileResetInternal());
      }
    });

    on<_ProfileResetInternal>((event, emit) {
      emit(const GoalState(isLoading: false));
    });

    on<_ProfileUpdatedInternal>((event, emit) {
      final p = event.profile;
      
      // Parse GoalType from string robustly
      GoalType? goal;
      if (p.selectedGoal != null) {
          try {
             final cleanName = p.selectedGoal!.contains('.') 
                ? p.selectedGoal!.split('.').last 
                : p.selectedGoal!;
             goal = GoalType.values.firstWhere((e) => e.name == cleanName);
          } catch (_) {}
      }

      emit(state.copyWith(
        selectedGoal: goal,
        gender: p.gender,
        weight: p.weight ?? 70.0,
        height: p.height ?? 170.0,
        age: p.age ?? 25,
        activityLevel: p.activityLevel ?? ActivityLevel.moderatelyActive,
        isOnboardingCompleted: p.onboardingCompleted ?? state.isOnboardingCompleted,
      ));
      
      // Update local prefs if Supabase says onboarding is done
      if (p.onboardingCompleted == true) {
        final userId = _repository.userId;
        if (userId != null) {
          _prefs.setBool('onboarding_completed_$userId', true);
        }
      }
    });
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadGoal(LoadGoal event, Emitter<GoalState> emit) async {
    final userId = _repository.userId;
    final localOnboarding = userId != null 
        ? (_prefs.getBool('onboarding_completed_$userId') ?? false)
        : false;
        
    emit(state.copyWith(
      isOnboardingCompleted: localOnboarding,
      isLoading: false, 
    ));
    // The repository stream will handle the actual data loading/syncing
  }

  Future<void> _onSetGoal(SetGoal event, Emitter<GoalState> emit) async {
    emit(state.copyWith(selectedGoal: event.goalType));
    await _repository.updateProfile({'selected_goal': event.goalType.name});
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<GoalState> emit) async {
    // Optimistic UI Update handled by emit in bloc if needed, 
    // but repository stream will eventually bring the truth.
    final Map<String, dynamic> updates = {};
    if (event.fullName != null) updates['full_name'] = event.fullName;
    if (event.gender != null) updates['gender'] = event.gender!.name;
    if (event.weight != null) updates['current_weight'] = event.weight;
    if (event.height != null) updates['height'] = event.height;
    if (event.age != null) updates['age'] = event.age;
    if (event.activityLevel != null) updates['activity_level'] = event.activityLevel!.name;

    // Recalculate calorie goal if biometrics changed
    final newState = state.copyWith(
      gender: event.gender,
      weight: event.weight,
      height: event.height,
      age: event.age,
      activityLevel: event.activityLevel,
    );
    updates['calorie_goal'] = newState.calorieTarget.toInt();
    updates['target_weight'] = newState.idealWeight;

    // Optimistic UI Update
    emit(newState);

    try {
      await _repository.updateProfile(updates);
    } catch (e) {
      debugPrint('GoalBloc: Failed to update profile: $e');
      // On failure, the reactive stream will eventually revert to truth, 
      // but we could also emit an error state here if needed.
    }
  }

  Future<void> _onUpdateTargetWeight(UpdateTargetWeight event, Emitter<GoalState> emit) async {
    await _repository.updateProfile({'target_weight': event.targetWeight});
  }

  Future<void> _onCompleteOnboarding(CompleteOnboarding event, Emitter<GoalState> emit) async {
    emit(state.copyWith(isLoading: true));
    final userId = _repository.userId;
    try {
      await _repository.updateProfile({'onboarding_completed': true});
      if (userId != null) {
        await _prefs.setBool('onboarding_completed_$userId', true);
        await _prefs.remove('onboarding_step_$userId'); // Cleanup
      }
      emit(state.copyWith(isOnboardingCompleted: true, isLoading: false));
    } catch (e) {
      if (userId != null) {
        await _prefs.setBool('onboarding_completed_$userId', true);
      }
      emit(state.copyWith(isOnboardingCompleted: true, isLoading: false));
    }
  }
}

// Internal event for stream updates
class _ProfileUpdatedInternal extends GoalEvent {
  final UserProfile profile;
  const _ProfileUpdatedInternal(this.profile);
  @override
  List<Object?> get props => [profile];
}

class _ProfileResetInternal extends GoalEvent {
  const _ProfileResetInternal();
}
