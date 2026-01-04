import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';
import 'package:caloric_mobile/features/progress/bloc/progress_bloc.dart';
import 'package:caloric_mobile/features/goals/bloc/goal_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        // We no longer block the whole screen with a spinner.
        // Sub-widgets will show their own state, prioritizing cached data.

        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.meshGradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                'PROGRESS',
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
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  _buildStatCards(context, state),
                  const SizedBox(height: 24),
                  _buildBMICard(context, state),
                  const SizedBox(height: 24),
                   _buildMacroStats(state),
                  const SizedBox(height: 24),
                  _buildWeightProgressCard(state, context),
                  const SizedBox(height: 24),
                  _buildDailyCaloriesCard(context, state),
                  const SizedBox(height: 150),
                ].animate(interval: 50.ms).fade(duration: 400.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCards(BuildContext context, ProgressState state) {
    final currentWeight = state.weightHistory.isNotEmpty 
        ? state.weightHistory.last['weight'].toString() 
        : '--';

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT WEIGHT',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentWeight,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'KG',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PremiumButton(
                  text: 'LOG',
                  onPressed: () => _showWeightLogDialog(context),
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            child: Column(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 42),
                const SizedBox(height: 4),
                Text(
                  state.history.length.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'TOTAL LOGS',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final completed = index < min(5, state.history.length);
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: completed ? Colors.white : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightProgressCard(ProgressState state, BuildContext context) {
    final spots = state.weightHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['weight'] as num).toDouble());
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEIGHT TRENDS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Icon(Icons.show_chart_rounded, size: 18, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: spots.isEmpty 
              ? const Center(child: Text('No trends yet', style: TextStyle(color: AppColors.textSecondary)))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.white,
                        barWidth: 4,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 4,
                            color: Colors.black,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1W', '1M', '3M', '6M'].map((label) {
              final isSelected = (label == '1W' && state.selectedDays == 7) ||
                                 (label == '1M' && state.selectedDays == 30);
              return GestureDetector(
                onTap: () {
                   final days = label == '1W' ? 7 : (label == '1M' ? 30 : 90);
                   context.read<ProgressBloc>().add(LoadProgressData(days: days));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? Colors.white : AppColors.glassBorder),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.black : Colors.white38,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCaloriesCard(BuildContext context, ProgressState state) {
    final dailyData = state.dailyCalories;
    final int goal = context.watch<GoalBloc>().state.calorieTarget.toInt();
    
    // Last 7 days
    final days = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return {
        'date': date,
        'calories': dailyData[DateTime(date.year, date.month, date.day)] ?? 0,
        'label': DateFormat('E').format(date)[0], // M, T, W...
      };
    });

    final avg = (days.fold<int>(0, (sum, item) => sum + (item['calories'] as int)) / 7).round();
    final adherence = goal > 0 ? (avg / goal * 100).toInt() : 0;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALORIE CONSISTENCY',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avg.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'avg kcal',
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: adherence > 110 ? AppColors.error.withOpacity(0.2) : AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: adherence > 110 ? AppColors.error.withOpacity(0.3) : AppColors.success.withOpacity(0.3)
                  ),
                ),
                child: Text(
                  '${adherence}% of Goal',
                  style: GoogleFonts.outfit(
                    color: adherence > 110 ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: goal.toDouble() > 0 ? goal.toDouble() : 2000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()]['label'] as String,
                            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final cals = days[i]['calories'] as int;
                  final isOver = goal > 0 && cals > goal * 1.1; // 10% buffer
                  final isUnder = goal > 0 && cals < goal * 0.8;
                  
                  Color barColor = Colors.white;
                  if (goal > 0) {
                     if (isOver) barColor = AppColors.error; 
                     else if (isUnder) barColor = Colors.white38;
                     else barColor = AppColors.success;
                  }

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: cals.toDouble(),
                        color: barColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: max((goal * 1.2).toDouble(), 2500.0), // Max height
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ],
                  );
                }),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goal.toDouble(),
                      color: AppColors.primary.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [4, 2],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 0, bottom: 4),
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                        labelResolver: (line) => 'GOAL',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBMICard(BuildContext context, ProgressState state) {
    // Get Height from GoalBloc
    final homeState = context.watch<GoalBloc>().state;
    final heightCm = homeState.height;
    
    // Get Weight from ProgressBloc (most recent)
    final weightKg = state.weightHistory.isNotEmpty 
        ? (state.weightHistory.last['weight'] as num).toDouble()
        : homeState.weight;

    if (heightCm <= 0 || weightKg <= 0) return const SizedBox.shrink();

    final bmi = weightKg / pow(heightCm / 100, 2);
    
    String label = 'NORMAL';
    Color color = AppColors.success;
    
    if (bmi < 18.5) { label = 'UNDERWEIGHT'; color = Colors.orange; }
    else if (bmi >= 25 && bmi < 30) { label = 'OVERWEIGHT'; color = Colors.orange; }
    else if (bmi >= 30) { label = 'OBESE'; color = AppColors.error; }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              bmi.toStringAsFixed(1),
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI SCORE',
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Based on ${heightCm.toInt()}cm height',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStats(ProgressState state) {
    if (state.history.isEmpty) return const SizedBox.shrink();

    // Calculate Totals
    var totalCals = 0;
    var totalP = 0;
    var totalC = 0;
    var totalF = 0;

    for (var log in state.history) {
      totalCals += log.calories;
      totalP += log.protein ?? 0;
      totalC += log.carbs ?? 0;
      totalF += log.fat ?? 0;
    }

    // Avoid division by zero
    if (totalCals == 0) return const SizedBox.shrink();

    // Calculate Percentages (approximate by calories)
    // Protein = 4cal/g, Carbs = 4cal/g, Fat = 9cal/g
    final pCal = totalP * 4;
    final cCal = totalC * 4;
    final fCal = totalF * 9;
    final totalMacroCal = pCal + cCal + fCal;
    
    if (totalMacroCal == 0) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MACRO DISTRIBUTION',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMacroBar('PRO', pCal / totalMacroCal, AppColors.protein),
              const SizedBox(width: 12),
              _buildMacroBar('CARB', cCal / totalMacroCal, AppColors.carbs),
              const SizedBox(width: 12),
              _buildMacroBar('FAT', fCal / totalMacroCal, AppColors.fats),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, double percent, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
              Text('${(percent * 100).toInt()}%', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white10,
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightLogDialog(BuildContext context) {
    final controller = TextEditingController();
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
              Text(
                'LOG WEIGHT',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    suffixText: 'KG',
                    suffixStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumButton(
                      text: 'SAVE',
                      onPressed: () {
                        final weight = double.tryParse(controller.text.trim());
                        if (weight != null && weight > 0) {
                          context.read<ProgressBloc>().add(AddWeightLog(weight));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Weight logged successfully! ⚖️'),
                              backgroundColor: AppColors.surfaceLight,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn(),
      ),
    );
  }
}
