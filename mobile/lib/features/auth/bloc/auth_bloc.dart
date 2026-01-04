import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  AuthSignUpRequested(this.email, this.password, this.name);
  @override
  List<Object?> get props => [email, password, name];
}
class AuthVerifyOtpRequested extends AuthEvent {
  final String email;
  final String token;
  AuthVerifyOtpRequested(this.email, this.token);
  @override
  List<Object?> get props => [email, token];
}
class AuthSignOutRequested extends AuthEvent {}
class AuthDeleteAccountRequested extends AuthEvent {}
class AuthStateChanged extends AuthEvent {
  final supa.AuthState state;
  AuthStateChanged(this.state);
  @override
  List<Object?> get props => [state];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final supa.User user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class AuthOtpRequired extends AuthState {
  final String email;
  AuthOtpRequired(this.email);
  @override
  List<Object?> get props => [email];
}
class Unauthenticated extends AuthState {}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final supa.SupabaseClient supabase;
  final SharedPreferences prefs;
  late final StreamSubscription<supa.AuthState> _authSubscription;

  AuthBloc(this.supabase, this.prefs) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthDeleteAccountRequested>(_onAuthDeleteAccountRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthVerifyOtpRequested>(_onAuthVerifyOtpRequested);

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.session == null) {
        // ROBUSTNESS: Clear local onboarding state when user is logged out or deleted
        // This prevents new users from "inheriting" the progress of the previous user.
        prefs.remove('onboarding_step');
        prefs.remove('onboarding_completed');
        debugPrint('AuthBloc: Cleared local onboarding preferences');
      }
      add(AuthStateChanged(data));
    });
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      emit(Authenticated(session.user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (response.user != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(AuthFailure('Login failed'));
      }
    } on supa.AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        emit(AuthOtpRequired(event.email));
      } else {
        emit(AuthFailure(e.message));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signUp(
        email: event.email,
        password: event.password,
        data: {'full_name': event.name},
        emailRedirectTo: 'io.supabase.caloric://login-callback',
      );
      print('AuthBloc: Signup successful for ${response.user?.email}');
      if (response.user != null) {
        // Profile is now created automatically by the Postgres Trigger (handle_new_user)
        if (response.session != null) {
          emit(Authenticated(response.user!));
        } else {
          emit(AuthOtpRequired(event.email));
        }
      } else {
        emit(AuthFailure('Signup failed'));
      }
    } on supa.AuthException catch (e) {
      debugPrint('AuthBloc: AuthException during signup: Code: ${e.statusCode}, Msg: ${e.message}');
      emit(AuthFailure(e.message));
    } catch (e) {
      debugPrint('AuthBloc: Unexpected error during signup: $e');
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthVerifyOtpRequested(AuthVerifyOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.verifyOTP(
        email: event.email,
        token: event.token,
        type: supa.OtpType.signup,
      );
      if (response.session != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(AuthFailure('Invalid or expired code'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await supabase.auth.signOut();
  }

  Future<void> _onAuthDeleteAccountRequested(AuthDeleteAccountRequested event, Emitter<AuthState> emit) async {
    final previousState = state;
    emit(AuthLoading());
    try {
      debugPrint('AuthBloc: Attempting account deletion via RPC...');
      // 1. Delete the user and all their data via RPC
      await supabase.rpc('delete_own_account').timeout(const Duration(seconds: 15));
      
      debugPrint('AuthBloc: RPC Success. Signing out to clear local session...');
      // 2. Clear local session. We use a short timeout because the account is already gone.
      try {
        await supabase.auth.signOut().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('AuthBloc: SignOut failed (expected if session already invalidated): $e');
      }
      
      emit(Unauthenticated());
    } on TimeoutException {
      debugPrint('AuthBloc: Deletion RPC timed out');
      emit(AuthFailure('Request timed out. Please check your connection.'));
      if (previousState is Authenticated) emit(previousState);
    } on supa.PostgrestException catch (e) {
      debugPrint('AuthBloc: Database error deleting account: ${e.message} (Code: ${e.code})');
      emit(AuthFailure('Database Error: ${e.message}'));
      if (previousState is Authenticated) emit(previousState);
    } catch (e) {
      debugPrint('AuthBloc: Unexpected error deleting account: $e');
      emit(AuthFailure('Failed to delete account: ${e.toString()}'));
      if (previousState is Authenticated) emit(previousState);
    }
  }

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    final session = event.state.session;
    if (session != null) {
      emit(Authenticated(session.user));
    } else {
      emit(Unauthenticated());
    }
  }
}

