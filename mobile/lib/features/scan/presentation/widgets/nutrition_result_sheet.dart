import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caloric_mobile/features/home/bloc/home_bloc.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';

class NutritionResultSheet extends StatelessWidget {
  final Map<String, dynamic> result;

  const NutritionResultSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final foodName = result['foodName'] ?? 'Unknown Food';
    final calories = (result['calories'] as num?)?.toInt() ?? 0;
    final protein = (result['protein'] as num?)?.toInt() ?? 0;
    final carbs = (result['carbs'] as num?)?.toInt() ?? 0;
    final fat = (result['fat'] as num?)?.toInt() ?? 0;
    final ingredients = result['ingredients'] as List<dynamic>? ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50, height: 5, 
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))
            ),
          ),
          const SizedBox(height: 24),
          Text('ANALYSIS COMPLETE', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
          
          const SizedBox(height: 8),
          Text(foodName.toString().toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _macroChip('Calories', '$calories', Colors.white),
               _macroChip('Protein', '${protein}g', AppColors.protein),
               _macroChip('Carbs', '${carbs}g', AppColors.carbs),
               _macroChip('Fat', '${fat}g', AppColors.fats),
            ],
          ),

          const SizedBox(height: 24),
          _buildGoalImpact(context, calories, protein, carbs, fat),

          const SizedBox(height: 24),
          if (ingredients.isNotEmpty) ...[
            Text('DEEP ANALYSIS', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: ingredients.map((ing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ing['name'] ?? '', style: GoogleFonts.outfit(color: Colors.white)),
                         Text('${ing['calories']} kcal', style: GoogleFonts.outfit(color: Colors.white54)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          PremiumButton(
            text: 'LOG TO DIARY',
            onPressed: () {
              context.read<HomeBloc>().add(AddFoodRequested(
                name: foodName,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                ingredients: ingredients,
              ));
              Navigator.pop(context);
              Navigator.pop(context); // Close ScanPage
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGoalImpact(BuildContext context, int cal, int pro, int carb, int fat) {
    final homeState = context.read<HomeBloc>().state;
    final profile = homeState.profile;
    if (profile == null) return const SizedBox.shrink();

    final calPct = (cal / profile.calorieGoal * 100).clamp(0, 100).toInt();
    final proPct = (pro / profile.proteinGoal * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GOAL IMPACT', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'This meal covers $calPct% of your calories and $proPct% of your protein goal for today.',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
