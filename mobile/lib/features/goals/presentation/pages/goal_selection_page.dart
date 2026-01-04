import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/features/goals/bloc/goal_bloc.dart';
import 'package:caloric_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:caloric_mobile/core/models/data_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalSelectionPage extends StatefulWidget {
  const GoalSelectionPage({super.key});

  @override
  State<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final userId = context.read<AuthBloc>().supabase.auth.currentUser?.id;
    if (userId == null) return;

    final savedPage = _prefs?.getInt('onboarding_step_$userId') ?? 0;
    if (savedPage > 0 && mounted) {
      debugPrint('GoalSelectionPage: Resuming onboarding at step $savedPage for $userId');
      setState(() {
        _currentPage = savedPage;
      });
      // Use post-frame callback to ensure PageView is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(savedPage);
        }
      });
    }
  }

  void _saveStep(int step) {
    final userId = context.read<AuthBloc>().supabase.auth.currentUser?.id;
    if (userId != null) {
      _prefs?.setInt('onboarding_step_$userId', step);
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      debugPrint('GoalSelectionPage: Moving to next page');
      final nextStep = _currentPage + 1;
      _saveStep(nextStep);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      debugPrint('GoalSelectionPage: Final step reached, triggering CompleteOnboarding');
      context.read<GoalBloc>().add(CompleteOnboarding());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildGoalStep(),
                  _buildGenderStep(),
                  _buildBiometricsStep(),
                  _buildActivityStep(),
                  _buildFinalStep(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                final prevStep = _currentPage - 1;
                _saveStep(prevStep);
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          const Spacer(),
          Text(
            '${_currentPage + 1} of 5',
            style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          bool canContinue = false;
          if (_currentPage == 0) canContinue = state.selectedGoal != null;
          if (_currentPage == 1) canContinue = state.gender != null;
          if (_currentPage >= 2) canContinue = true;

          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canContinue ? () {
                debugPrint('GoalSelectionPage: CONTINUE button pressed (canContinue=$canContinue)');
                _nextPage();
              } : null,
              child: state.isLoading 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : Text(_currentPage == 4 ? 'GET STARTED' : 'CONTINUE'),
            ),
          );
        },
      ),
    );
  }

  // --- STEPS ---

  Widget _buildGoalStep() {
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepTitle('WHAT IS YOUR\nMAIN GOAL?'),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: Goal.presets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final goal = Goal.presets[index];
                    final isSelected = state.selectedGoal == goal.type;
                    return _selectorCard(
                      isSelected,
                      goal.title,
                      goal.description,
                      () {
                        debugPrint('GoalSelectionPage: Selected goal ${goal.type}');
                        context.read<GoalBloc>().add(SetGoal(goal.type));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderStep() {
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepTitle('SELECT YOUR\nGENDER'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _genderCard(state.gender == Gender.male, 'MALE', Icons.male, () {
                    context.read<GoalBloc>().add(const UpdateProfile(gender: Gender.male));
                  })),
                  const SizedBox(width: 16),
                  Expanded(child: _genderCard(state.gender == Gender.female, 'FEMALE', Icons.female, () {
                    context.read<GoalBloc>().add(const UpdateProfile(gender: Gender.female));
                  })),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBiometricsStep() {
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _stepTitle('YOUR BIOMETRICS', centered: true),
              const SizedBox(height: 32), // Reduced from 48
              _biometricPicker(
                label: 'WEIGHT',
                value: '${state.weight.round()}',
                unit: 'kg',
                current: state.weight,
                min: 40,
                max: 150,
                onChanged: (val) => context.read<GoalBloc>().add(UpdateProfile(weight: val)),
              ),
              const SizedBox(height: 32), // Reduced from 40
              _biometricPicker(
                label: 'HEIGHT',
                value: '${state.height.round()}',
                unit: 'cm',
                current: state.height,
                min: 120,
                max: 220,
                onChanged: (val) => context.read<GoalBloc>().add(UpdateProfile(height: val)),
              ),
              const SizedBox(height: 32), // Reduced from 40
              _biometricPicker(
                label: 'AGE',
                value: '${state.age}',
                unit: 'years',
                current: state.age.toDouble(),
                min: 15,
                max: 80,
                onChanged: (val) => context.read<GoalBloc>().add(UpdateProfile(age: val.round())),
              ),
              const SizedBox(height: 32), // Padding at bottom
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepTitle('ACTIVITY LEVEL'),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: ActivityLevel.values.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final level = ActivityLevel.values[index];
                return BlocBuilder<GoalBloc, GoalState>(
                  builder: (context, state) {
                    final isSelected = state.activityLevel == level;
                    String title = '';
                    String desc = '';

                    switch (level) {
                      case ActivityLevel.sedentary:
                        title = 'SEDENTARY';
                        desc = 'Little or no exercise, desk job';
                        break;
                      case ActivityLevel.lightlyActive:
                        title = 'LIGHTLY ACTIVE';
                        desc = 'Light exercise 1-3 days/week';
                        break;
                      case ActivityLevel.moderatelyActive:
                        title = 'MODERATELY ACTIVE';
                        desc = 'Moderate exercise 3-5 days/week';
                        break;
                      case ActivityLevel.veryActive:
                        title = 'VERY ACTIVE';
                        desc = 'Hard exercise 6-7 days/week';
                        break;
                      case ActivityLevel.extraActive:
                        title = 'EXTRA ACTIVE';
                        desc = 'Hard daily exercise & physical job';
                        break;
                    }

                    return _selectorCard(isSelected, title, desc, () {
                      context.read<GoalBloc>().add(UpdateProfile(activityLevel: level));
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStep() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: AppColors.primary),
          const SizedBox(height: 30),
          Text(
            'YOU ARE ALL SET!',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Our AI is ready to calibrate your metabolism and help you reach your goals.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _stepTitle(String text, {bool centered = false}) {
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
    );
  }

  Widget _selectorCard(bool selected, String title, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(25) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            const SizedBox(height: 4),
            Text(desc, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _genderCard(bool selected, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(25) : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.primary : Colors.white24, size: 40),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _biometricPicker({
    required String label,
    required String value,
    required String unit,
    required double current,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              unit,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _precisionButton(Icons.remove, () {
              if (current > min) onChanged(current - 1);
            }),
            Expanded(
              child: Slider(
                value: current.clamp(min, max),
                min: min,
                max: max,
                activeColor: AppColors.primary,
                inactiveColor: Colors.white10,
                onChanged: onChanged,
              ),
            ),
            _precisionButton(Icons.add, () {
              if (current < max) onChanged(current + 1);
            }),
          ],
        ),
      ],
    );
  }

  Widget _precisionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
