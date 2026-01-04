import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';

class MacroRings extends StatelessWidget {
  final int protein;
  final int proteinGoal;
  final int carbs;
  final int carbsGoal;
  final int fat;
  final int fatGoal;
  final int calories;
  final int calorieGoal;

  const MacroRings({
    super.key,
    required this.protein,
    required this.proteinGoal,
    required this.carbs,
    required this.carbsGoal,
    required this.fat,
    required this.fatGoal,
    required this.calories,
    required this.calorieGoal,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY\'S ENERGY',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$calories',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: ' kcal',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Goal: $calorieGoal',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _buildTripleRing(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroLegend('Protein', protein, proteinGoal, const Color(0xFF6E56F8)),
              _buildMacroLegend('Carbs', carbs, carbsGoal, const Color(0xFF56F8D4)),
              _buildMacroLegend('Fats', fat, fatGoal, const Color(0xFFF85698)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripleRing() {
    // Calculate percentages
    final pP = (protein / proteinGoal).clamp(0.0, 1.0);
    final pC = (carbs / carbsGoal).clamp(0.0, 1.0);
    final pF = (fat / fatGoal).clamp(0.0, 1.0);

    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring (Protein)
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 10.0,
            percent: pP,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white.withOpacity(0.05),
            progressColor: const Color(0xFF6E56F8), // Purple
            animation: true,
            animationDuration: 1000,
          ),
          // Middle Ring (Carbs)
          CircularPercentIndicator(
            radius: 46.0,
            lineWidth: 10.0,
            percent: pC,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white.withOpacity(0.05),
            progressColor: const Color(0xFF56F8D4), // Teal
            animation: true,
            animationDuration: 1000,
          ),
          // Inner Ring (Fat)
          CircularPercentIndicator(
            radius: 32.0,
            lineWidth: 10.0,
            percent: pF,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.white.withOpacity(0.05),
            progressColor: const Color(0xFFF85698), // Pink
            animation: true,
            animationDuration: 1000,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLegend(String label, int val, int goal, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$val',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: '/${goal}g',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
