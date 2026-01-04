import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import '../models/data_models.dart';

class DataRepository {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  // Reactive Subjects
  final _profileSubject = BehaviorSubject<UserProfile?>();
  final _todayLogsSubject = BehaviorSubject<List<FoodLog>>();
  final _waterLogsSubject = BehaviorSubject<List<WaterLog>>();
  final _weightHistorySubject = BehaviorSubject<List<Map<String, dynamic>>>();

  // Streams
  Stream<UserProfile?> get profileStream => _profileSubject.stream;
  Stream<List<FoodLog>> get todayLogsStream => _todayLogsSubject.stream;
  Stream<List<WaterLog>> get waterLogsStream => _waterLogsSubject.stream;
  Stream<List<Map<String, dynamic>>> get weightHistoryStream => _weightHistorySubject.stream;

  DataRepository(this._supabase, this._prefs) {
    _init();
    // Re-init on auth changes (Professional Hardening)
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        _init();
      } else if (event == AuthChangeEvent.signedOut) {
        _clear();
      }
    });
  }

  String? get userId => _supabase.auth.currentUser?.id;

  void _init() {
    if (userId != null) {
      debugPrint('DataRepository: Initializing for $userId');
      _loadCachedData();
      _setupSubscriptions();
    }
  }

  void _clear() {
    debugPrint('DataRepository: Clearing for logout');
    _profileSub?.cancel();
    _foodSub?.cancel();
    _waterSub?.cancel();
    _profileSubject.add(null);
    _todayLogsSubject.add([]);
    _waterLogsSubject.add([]);
    _weightHistorySubject.add([]);
  }

  // --- CACHE MANAGEMENT ---

  void _loadCachedData() {
    try {
      final cachedProfile = _prefs.getString('cached_profile_$userId');
      if (cachedProfile != null) {
        _profileSubject.add(UserProfile.fromJson(json.decode(cachedProfile)));
      }

      final cachedLogs = _prefs.getString('cached_logs_$userId');
      if (cachedLogs != null) {
        final List<dynamic> decoded = json.decode(cachedLogs);
        _todayLogsSubject.add(decoded.map((e) => FoodLog.fromJson(e)).toList());
      }

      final cachedWater = _prefs.getString('cached_water_$userId');
      if (cachedWater != null) {
        final List<dynamic> decoded = json.decode(cachedWater);
        _waterLogsSubject.add(decoded.map((e) => WaterLog.fromJson(e)).toList());
      }
    } catch (e) {
      debugPrint('DataRepository: Cache load error: $e');
    }
  }

  // --- SUBSCRIPTIONS (INTERLINKING) ---

  StreamSubscription? _profileSub;
  StreamSubscription? _foodSub;
  StreamSubscription? _waterSub;

  void _setupSubscriptions() {
    if (userId == null) return;

    // 1. Profile Subscription
    _profileSub?.cancel();
    _profileSub = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId!)
        .listen((data) {
          if (data.isNotEmpty) {
            final profile = UserProfile.fromJson(data.first);
            _prefs.setString('cached_profile_$userId', json.encode(data.first));
            _profileSubject.add(profile);
          } else {
            // Unblock the stream even if no DB record exists yet
            _profileSubject.add(null);
          }
        });

    // 2. Food Logs Subscription (Last 7 days)
    final startDate = DateTime.now().subtract(const Duration(days: 7));
    _foodSub?.cancel();
    _foodSub = _supabase
        .from('food_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId!)
        .order('created_at', ascending: false)
        .listen((data) {
          final logs = data.map((e) => FoodLog.fromJson(e)).toList();
          _prefs.setString('cached_logs_$userId', json.encode(data));
          _todayLogsSubject.add(logs);
        });

    // 3. Water Logs Subscription
    _waterSub?.cancel();
    _waterSub = _supabase
        .from('water_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId!)
        .order('created_at', ascending: false)
        .listen((data) {
          final logs = data.map((e) => WaterLog.fromJson(e)).toList();
          _prefs.setString('cached_water_$userId', json.encode(data));
          _waterLogsSubject.add(logs);
        });
  }

  // --- ACTIONS ---

  Future<void> addFoodLog({
    required String name,
    required int calories,
    int? protein,
    int? carbs,
    int? fat,
    List<dynamic>? ingredients,
    String? imageUrl,
  }) async {
    if (userId == null) return;
    
    int attempts = 0;
    while (attempts < 3) {
      try {
        await _supabase.from('food_logs').insert({
          'user_id': userId,
          'name': name,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'ingredients': ingredients,
          'image_url': imageUrl,
        });
        return;
      } catch (e) {
        attempts++;
        debugPrint('DataRepository: addFoodLog attempt $attempts failed: $e');
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  Future<void> addWaterLog(int amountMl) async {
    if (userId == null) return;
    int attempts = 0;
    while (attempts < 3) {
      try {
        await _supabase.from('water_logs').insert({
          'user_id': userId,
          'amount_ml': amountMl,
        });
        return;
      } catch (e) {
        attempts++;
        debugPrint('DataRepository: addWaterLog attempt $attempts failed: $e');
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (userId == null) return;
    debugPrint('DataRepository: Updating profile for $userId with $updates');
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('DataRepository: Profile updated successfully');
    } catch (e) {
      debugPrint('DataRepository: Profile update failed: $e');
      rethrow;
    }
  }

  Future<void> addWeightEntry(double weight) async {
    if (userId == null) return;
    await _supabase.from('weight_history').insert({
      'user_id': userId,
      'weight': weight,
    });
    // Also update current weight in profile
    await updateProfile({'current_weight': weight});
  }

  Future<List<Map<String, dynamic>>> getWeightHistory(int days) async {
    if (userId == null) return [];
    final startDate = DateTime.now().subtract(Duration(days: days));
    final response = await _supabase
        .from('weight_history')
        .select()
        .eq('user_id', userId!)
        .gte('created_at', startDate.toIso8601String())
        .order('created_at');
    
    final history = (response as List).map((e) => e as Map<String, dynamic>).toList();
    _weightHistorySubject.add(history);
    return history;
  }

  // --- CHAT ---

  Future<void> addChatMessage({required String content, required bool isUser}) async {
    if (userId == null) return;
    await _supabase.from('chat_messages').insert({
      'user_id': userId,
      'content': content,
      'is_user': isUser,
    });
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    if (userId == null) return [];
    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: true);
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  // --- AI CONTEXT PROVIDER ---
  
  Map<String, dynamic> getUnifiedContext() {
    final profile = _profileSubject.value;
    final logs = _todayLogsSubject.value;
    final water = _waterLogsSubject.value;
    
    final now = DateTime.now();
    final todayLogs = logs.where((l) => 
      l.createdAt.year == now.year && 
      l.createdAt.month == now.month && 
      l.createdAt.day == now.day
    ).toList();

    final todayWater = water.where((w) => 
      w.createdAt.year == now.year && 
      w.createdAt.month == now.month && 
      w.createdAt.day == now.day
    ).fold<int>(0, (sum, w) => sum + w.amountMl);

    return {
      'profile': {
        'name': profile?.fullName,
        'goals': {
          'calories': profile?.calorieGoal,
          'protein': profile?.proteinGoal,
          'carbs': profile?.carbGoal,
          'fat': profile?.fatGoal,
          'water': profile?.waterGoal,
        },
        'current_biometrics': {
          'age': profile?.age,
          'weight': profile?.weight,
          'height': profile?.height,
          'activity': profile?.activityLevel?.name,
        }
      },
      'daily_stats': {
        'calories_consumed': todayLogs.fold<int>(0, (sum, l) => sum + l.calories),
        'protein_consumed': todayLogs.fold<int>(0, (sum, l) => sum + (l.protein ?? 0)),
        'carbs_consumed': todayLogs.fold<int>(0, (sum, l) => sum + (l.carbs ?? 0)),
        'fat_consumed': todayLogs.fold<int>(0, (sum, l) => sum + (l.fat ?? 0)),
        'water_intake_ml': todayWater,
      },
      'recent_food': todayLogs.take(5).map((l) => {
        'name': l.foodName,
        'calories': l.calories,
        'time': l.createdAt.toIso8601String(),
        'ingredients': l.ingredients,
      }).toList(),
      'weight_history': _weightHistorySubject.value.take(7).toList(),
    };
  }

  void dispose() {
    _profileSub?.cancel();
    _foodSub?.cancel();
    _waterSub?.cancel();
    _profileSubject.close();
    _todayLogsSubject.close();
    _waterLogsSubject.close();
    _weightHistorySubject.close();
  }
}
