import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/goals/bloc/goal_bloc.dart';
import 'features/goals/presentation/pages/goal_selection_page.dart';
import 'features/navigation/presentation/main_scaffold.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/coach/bloc/coach_bloc.dart';
import 'features/progress/bloc/progress_bloc.dart';

import 'core/repositories/data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await supabase.Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final repository = DataRepository(supabase.Supabase.instance.client, prefs);

  runApp(CaloricApp(prefs: prefs, repository: repository));
}

class CaloricApp extends StatelessWidget {
  final SharedPreferences prefs;
  final DataRepository repository;

  const CaloricApp({super.key, required this.prefs, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(supabase.Supabase.instance.client, prefs)..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => GoalBloc(repository, prefs),
        ),
        BlocProvider(
          create: (context) => HomeBloc(repository),
        ),
        BlocProvider(
          create: (context) => CoachBloc(repository),
        ),
        BlocProvider(
          create: (context) => ProgressBloc(repository),
        ),
      ],
      child: MaterialApp(
        title: 'Caloric.AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              debugPrint('AuthWrapper: Authenticated, triggering LoadGoal');
              context.read<GoalBloc>().add(LoadGoal());
            } else if (state is Unauthenticated) {
              debugPrint('AuthWrapper: Unauthenticated, clearing any open dialogs');
              // Close any open dialogs (like Delete Account or Settings) 
              // that were pushed onto the root navigator.
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
            }
          },
        ),
        BlocListener<GoalBloc, GoalState>(
          listenWhen: (previous, current) => !previous.isOnboardingCompleted && current.isOnboardingCompleted,
          listener: (context, state) {
            if (state.isOnboardingCompleted) {
              debugPrint('AuthWrapper: Onboarding completed, triggering data subscriptions');
              context.read<HomeBloc>().add(SubscribeToHomeData());
              context.read<ProgressBloc>().add(const LoadProgressData());
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          debugPrint('AuthWrapper: Builder State is $authState');
          if (authState is AuthInitial || authState is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          if (authState is Authenticated) {
            return BlocBuilder<GoalBloc, GoalState>(
              builder: (context, goalState) {
                debugPrint('AuthWrapper: GoalBuilder isLoading=${goalState.isLoading}, isOnboardingCompleted=${goalState.isOnboardingCompleted}');
                
                // Only show full-screen spinner if we are loading AND don't know the onboarding status yet.
                // If we know the onboarding status (cached or loaded), we show the appropriate screen immediately.
                if (goalState.isLoading && !goalState.isOnboardingCompleted && goalState.selectedGoal == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                }

                if (goalState.isOnboardingCompleted) {
                  return const MainScaffold();
                } else {
                  return const GoalSelectionPage();
                }
              },
            );
          } else {
            debugPrint('AuthWrapper: Unauthenticated, showing LoginPage');
            return const LoginPage();
          }
        },
      ),
    );
  }
}
