import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:caloric_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:caloric_mobile/features/goals/bloc/goal_bloc.dart';
import 'package:caloric_mobile/features/home/bloc/home_bloc.dart';
import 'package:caloric_mobile/core/models/data_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to HomeBloc to get Profile data (Name, Goals, etc.)
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              // ROBUSTNESS: Ensure any open dialog (like Delete Account) is closed 
              // before the AuthWrapper navigates to the LoginPage.
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
            }
            if (state is AuthFailure) {
              // If deletion fails, we also want to pop the dialog so the user can see the error
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final profile = state.profile;
          
          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.meshGradient,
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  'PROFILE',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileCard(context, profile),
                    const SizedBox(height: 32),
                    _buildSettingsSection('ACCOUNT', [
                      _settingsTile(context, Icons.person_outline_rounded, 'Personal Information', 
                        onTap: () => _showEditProfileDialog(context, profile)),
                      _settingsTile(context, Icons.notifications_none_rounded, 'Notifications',
                        onTap: () => _showNotificationsDialog(context)),
                      _settingsTile(context, Icons.lock_outline_rounded, 'Privacy & Security',
                        onTap: () => _showPrivacySecurityDialog(context)),
                    ]),
                    const SizedBox(height: 24),
                    _buildSettingsSection('GOALS', [
                      _settingsTile(context, Icons.track_changes_rounded, 'Daily Calorie Goal: ${profile?.calorieGoal ?? 2000}',
                        onTap: () => _showEditProfileDialog(context, profile)), // Editing profile updates goal
                      _settingsTile(context, Icons.monitor_weight_outlined, 'Target Weight: ${profile?.targetWeight?.toStringAsFixed(1) ?? "--"} kg',
                        onTap: () => _showEditTargetWeight(context, profile?.targetWeight)),
                    ]),
                    const SizedBox(height: 24),
                    _buildSettingsSection('SUPPORT', [
                      _settingsTile(context, Icons.help_outline_rounded, 'Help Center',
                        onTap: () => _showHelpCenter(context)),
                      _settingsTile(context, Icons.info_outline_rounded, 'About Caloric.AI',
                        onTap: () => _showAboutDialog(context)),
                    ]),
                    const SizedBox(height: 48),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthSignOutRequested());
                      },
                      child: Text(
                        'LOG OUT',
                        style: GoogleFonts.outfit(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 150),
                  ].animate(interval: 50.ms).fade(duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ... (existing _buildProfileCard and other widgets remain same, skipping to new Privacy Logic)

  void _showPrivacySecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Icon(Icons.security_rounded, color: Colors.white, size: 48),
               const SizedBox(height: 16),
               Text('PRIVACY & SECURITY', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 24),
               
               // Change Password Tile
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                   child: const Icon(Icons.password_rounded, color: Colors.white70, size: 20),
                 ),
                 title: Text('Change Password', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                 subtitle: Text('Receive an email to reset it', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                 onTap: () {
                    Navigator.pop(context);
                    _triggerPasswordReset(context);
                 },
               ),
               const Divider(color: Colors.white10),
               
               // Delete Account Tile
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                   child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                 ),
                 title: Text('Delete Account', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.w600)),
                 subtitle: Text('Permanently remove your data', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                 onTap: () {
                    Navigator.pop(context);
                    _showDeleteAccountConfirmation(context);
                 },
               ),
               
               const SizedBox(height: 24),
               PremiumButton(text: 'CLOSE', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerPasswordReset(BuildContext context) async {
      try {
        final email = Supabase.instance.client.auth.currentUser?.email;
        if (email != null) {
           await Supabase.instance.client.auth.resetPasswordForEmail(email);
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Reset email sent to $email 📧'), backgroundColor: AppColors.primary),
             );
           }
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Error sending reset email'), backgroundColor: AppColors.error),
           );
        }
      }
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final controller = TextEditingController();
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('DELETE ACCOUNT', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This action cannot be undone. All your data will be permanently lost.',
                  style: GoogleFonts.outfit(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  'Type DELETE to confirm:',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  enabled: !isDeleting,
                  style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    hintStyle: TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
              ),
              TextButton(
                onPressed: isDeleting ? null : () {
                  if (controller.text.trim().toUpperCase() == 'DELETE') {
                    setDialogState(() => isDeleting = true);
                    context.read<AuthBloc>().add(AuthDeleteAccountRequested());
                    
                    // The AuthBloc will handle state changes (emit Unauthenticated/AuthFailure)
                    // which will cause the main AuthWrapper to navigate away.
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please type DELETE in the box'), backgroundColor: AppColors.error),
                    );
                  }
                },
                child: isDeleting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2))
                  : const Text('CONFIRM', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildProfileCard(BuildContext context, UserProfile? profile) {
    final name = profile?.fullName ?? 'Guest User';
    final initials = name.trim().isNotEmpty 
        ? name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
        : 'U';

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white, // High contrast premium look
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.outfit(
                  color: Colors.black, // Dark text on white bg
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    'PREMIUM MEMBER',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileDialog(context, profile),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String label, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white60, size: 20),
        ),
        title: Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    
    // ROBUST INTERLINKING: Use Bloc state as fallback for the UI to ensure it's "Automatically Filled"
    final goalState = context.read<GoalBloc>().state;
    
    final nameController = TextEditingController(text: profile.fullName ?? '');
    final ageController = TextEditingController(text: (profile.age ?? goalState.age).toString());
    final heightController = TextEditingController(text: (profile.height ?? goalState.height).toStringAsFixed(1));
    final weightController = TextEditingController(text: (profile.weight ?? goalState.weight).toStringAsFixed(1));
    
    // State variables captured by the closure with fallbacks
    Gender? localGender = profile.gender ?? goalState.gender;
    ActivityLevel? localActivity = profile.activityLevel ?? goalState.activityLevel;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('EDIT PROFILE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 24),
                    _buildTextField('Full Name', nameController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Age', ageController, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Height (cm)', heightController, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Weight (kg)', weightController, isNumber: true),
                    const SizedBox(height: 16),
                    
                    // GENDER DROPDOWN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gender', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Gender>(
                              value: localGender,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              hint: Text('Select Gender', style: GoogleFonts.outfit(color: Colors.white54)),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                              items: Gender.values.map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.name.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white)),
                              )).toList(),
                              onChanged: (val) => setState(() => localGender = val),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ACTIVITY LEVEL DROPDOWN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activity Level', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ActivityLevel>(
                              value: localActivity,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              hint: Text('Select Activity', style: GoogleFonts.outfit(color: Colors.white54)),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                              items: ActivityLevel.values.map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.name.toUpperCase().replaceAll('ACTIVE', ' ACTIVE'), style: GoogleFonts.outfit(color: Colors.white)),
                              )).toList(),
                              onChanged: (val) => setState(() => localActivity = val),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(context), 
                        child: Text('CANCEL', style: TextStyle(color: Colors.white60))
                      )),
                      Expanded(child: PremiumButton(
                        text: isSaving ? 'SAVING...' : 'SAVE', 
                        onPressed: isSaving ? () {} : () {
                          // Dismiss Keyboard
                          FocusScope.of(context).unfocus();

                          // Validation
                          final name = nameController.text.trim();
                          final age = int.tryParse(ageController.text);
                          final height = double.tryParse(heightController.text);
                          final weight = double.tryParse(weightController.text);
                          
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name'), backgroundColor: AppColors.error));
                            return;
                          }
                          if (age == null || age <= 0 || age > 120) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid age'), backgroundColor: AppColors.error));
                            return;
                          }
                          if (height == null || height <= 50 || height > 300) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid height (cm)'), backgroundColor: AppColors.error));
                            return;
                          }
                          if (weight == null || weight <= 20 || weight > 500) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid weight (kg)'), backgroundColor: AppColors.error));
                            return;
                          }
                          if (localGender == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a gender'), backgroundColor: AppColors.error));
                            return;
                          }
                          if (localActivity == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an activity level'), backgroundColor: AppColors.error));
                            return;
                          }

                          // Proceed to Save
                          setState(() => isSaving = true);
                          
                          context.read<GoalBloc>().add(UpdateProfile(
                            fullName: name,
                            age: age,
                            height: height,
                            weight: weight,
                            gender: localGender,
                            activityLevel: localActivity,
                          ));

                          // Wait a bit for propagation (UX delay + API time)
                          Future.delayed(const Duration(milliseconds: 1000), () {
                             if (context.mounted) {
                               context.read<HomeBloc>().add(SubscribeToHomeData()); // Force refresh
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Profile Updated Successfully! 🚀'), backgroundColor: AppColors.primary)
                               );
                             }
                          });
                      })),
                    ]),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  void _showNotificationsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved state (default to true)
    bool daily = prefs.getBool('notify_daily') ?? true;
    bool weekly = prefs.getBool('notify_weekly') ?? true;
    bool features = prefs.getBool('notify_features') ?? false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 48),
                   const SizedBox(height: 16),
                   Text('NOTIFICATIONS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 24),
                   _buildSwitchTile('Daily Reminders', daily, (val) {
                     setState(() => daily = val);
                     prefs.setBool('notify_daily', val);
                   }),
                   _buildSwitchTile('Weekly Progress', weekly, (val) {
                     setState(() => weekly = val);
                     prefs.setBool('notify_weekly', val);
                   }),
                   _buildSwitchTile('New Features', features, (val) {
                     setState(() => features = val);
                     prefs.setBool('notify_features', val);
                   }),
                   const SizedBox(height: 24),
                   PremiumButton(text: 'DONE', onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.outfit(color: Colors.white70)),
          Switch(
            value: value, 
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Help Center', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
             children: [
               _buildFaqItem('How is my goal calculated?', 'We use the Mifflin-St Jeor equation based on your height, weight, age, and activity level.'),
               const SizedBox(height: 16),
               _buildFaqItem('Can I change my diet type?', 'Yes, go to the Goals section and select a new preset.'),
               const SizedBox(height: 16),
               _buildFaqItem('Is the AI accurate?', 'The AI provides estimates based on visual recognition. Always verify with labels if possible.'),
             ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(a, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  void _showComingSoon(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Coming Soon in v2.0! 🚀'),
        backgroundColor: AppColors.surfaceLight,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Caloric.AI', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Version 1.0.0\nBuilt with ❤️ by Deepmind.', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('COOL'),
          ),
        ],
      ),
    );
  }

  void _showEditTargetWeight(BuildContext context, double? currentTarget) {
    // ... existing implementation ...
    final controller = TextEditingController(text: currentTarget?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TARGET WEIGHT', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(border: InputBorder.none, suffixText: 'KG'),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white60)))),
                Expanded(child: PremiumButton(text: 'SAVE', onPressed: () {
                    final val = double.tryParse(controller.text);
                    if (val != null) {
                      context.read<GoalBloc>().add(UpdateTargetWeight(val));
                      Navigator.pop(context);
                      // Trigger refresh
                      context.read<HomeBloc>().add(SubscribeToHomeData());
                    }
                })),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
