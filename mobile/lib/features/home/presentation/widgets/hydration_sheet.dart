import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';
import 'package:caloric_mobile/features/home/bloc/home_bloc.dart';

class HydrationSheet extends StatelessWidget {
  final int currentWater;
  final int waterGoal;

  const HydrationSheet({
    super.key,
    required this.currentWater,
    this.waterGoal = 2500,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceLight, AppColors.background],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildProgressCircle(),
                const SizedBox(height: 40),
                _buildOptionsGrid(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'HYDRATION TRACKER',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCircle() {
    final double percentage = (currentWater / waterGoal).clamp(0.0, 1.0);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 12,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: percentage,
            strokeWidth: 12,
            color: Colors.blueAccent,
            backgroundColor: Colors.transparent,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 32),
            const SizedBox(height: 4),
            Text(
              '${(percentage * 100).toInt()}%',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
             Text(
              '$currentWater / $waterGoal ml',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsGrid(BuildContext context) {
    final options = [
      {'label': 'Sip', 'amount': 100, 'icon': Icons.local_drink_rounded},
      {'label': 'Glass', 'amount': 250, 'icon': Icons.local_cafe_rounded},
      {'label': 'Bottle', 'amount': 500, 'icon': Icons.network_check_rounded /* looks like bottle */},
      {'label': 'Jug', 'amount': 750, 'icon': Icons.kitchen_rounded},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: options.map((opt) {
        return GestureDetector(
          onTap: () {
            context.read<HomeBloc>().add(AddWaterRequested(opt['amount'] as int));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                 content: Text('Added ${opt['amount']}ml water 💧'),
                 backgroundColor: AppColors.surfaceLight,
                 behavior: SnackBarBehavior.floating,
                 duration: const Duration(seconds: 1),
              ),
            );
          },
          child: GlassCard(
            width: (MediaQuery.of(context).size.width - 64) / 2, // 2 columns
            padding: const EdgeInsets.symmetric(vertical: 20),
            borderRadius: 20,
            child: Column(
              children: [
                Icon(opt['icon'] as IconData, color: Colors.blueAccent, size: 28),
                const SizedBox(height: 12),
                Text(
                  (opt['label'] as String).toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '+${opt['amount']}ml',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
