import 'package:equatable/equatable.dart';

enum Gender { male, female, other }
enum ActivityLevel { sedentary, lightlyActive, moderatelyActive, veryActive, extraActive }

class FoodLog extends Equatable {
  final String id;
  final String userId;
  final String foodName;
  final int calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final String? imageUrl;
  final List<dynamic>? ingredients; // Store detailed breakdown
  final DateTime createdAt;

  const FoodLog({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.imageUrl,
    this.ingredients,
    required this.createdAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'],
      userId: json['user_id'],
      foodName: json['name'],
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
      imageUrl: json['image_url'],
      ingredients: json['ingredients'] != null ? json['ingredients'] as List : [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'image_url': imageUrl,
      'ingredients': ingredients, // Save to new JSONB column
    };
  }

  @override
  List<Object?> get props => [id, userId, foodName, calories, protein, carbs, fat, imageUrl, ingredients, createdAt];
}

class WaterLog extends Equatable {
  final String id;
  final String userId;
  final int amountMl;
  final DateTime createdAt;

  const WaterLog({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.createdAt,
  });

  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['id'],
      userId: json['user_id'],
      amountMl: json['amount_ml'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, amountMl, createdAt];
}

class UserProfile extends Equatable {
  final String id;
  final String? fullName;
  final String? selectedGoal;
  final int calorieGoal;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;
  final int waterGoal;
  final double? targetWeight;
  final int? age;
  final double? height;
  final double? weight;
  final Gender? gender;
  final ActivityLevel? activityLevel;
  final bool? onboardingCompleted; // Add this

  const UserProfile({
    required this.id,
    this.fullName,
    this.selectedGoal,
    this.calorieGoal = 2000,
    this.proteinGoal = 150,
    this.carbGoal = 250,
    this.fatGoal = 70,
    this.waterGoal = 2500,
    this.targetWeight,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.activityLevel,
    this.onboardingCompleted,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      selectedGoal: json['selected_goal'],
      calorieGoal: json['calorie_goal'] ?? 2000,
      proteinGoal: json['protein_goal'] ?? 150,
      carbGoal: json['carb_goal'] ?? 250,
      fatGoal: json['fat_goal'] ?? 70,
      waterGoal: json['water_goal'] ?? 2500,
      targetWeight: (json['target_weight'] as num?)?.toDouble(),
      age: json['age'],
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['current_weight'] as num?)?.toDouble(),
      gender: json['gender'] != null 
          ? Gender.values.firstWhere((e) => e.name == json['gender'], orElse: () => Gender.other) 
          : null,
      activityLevel: json['activity_level'] != null 
          ? ActivityLevel.values.firstWhere((e) => e.name == json['activity_level'], orElse: () => ActivityLevel.moderatelyActive) 
          : null,
      onboardingCompleted: json['onboarding_completed'],
    );
  }

  @override
  List<Object?> get props => [id, fullName, selectedGoal, calorieGoal, proteinGoal, carbGoal, fatGoal, waterGoal, targetWeight, age, height, weight, gender, activityLevel, onboardingCompleted];
}
