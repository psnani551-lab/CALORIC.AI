import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';
import 'package:caloric_mobile/features/home/bloc/home_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:caloric_mobile/features/home/presentation/widgets/macro_rings.dart';
import 'package:caloric_mobile/features/home/presentation/widgets/hydration_sheet.dart';
import 'package:caloric_mobile/core/models/data_models.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // We no longer block the whole screen. 
        // Sub-widgets will handle their own loading states if needed, 
        // but we prioritize showing cached data.

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.meshGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(state),
                    const SizedBox(height: 24),
                    _buildWeeklyCalendar(),
                    const SizedBox(height: 24),
                    _buildChartSection(state),
                    const SizedBox(height: 24),
                    MacroRings(
                      calories: state.totalCalories,
                      calorieGoal: state.profile?.calorieGoal.toInt() ?? 2000,
                      protein: state.totalProtein,
                      proteinGoal: state.profile?.proteinGoal.toInt() ?? 150,
                      carbs: state.totalCarbs,
                      carbsGoal: state.profile?.carbGoal.toInt() ?? 250,
                      fat: state.totalFat,
                      fatGoal: state.profile?.fatGoal.toInt() ?? 70,
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    Text(
                      'TIMELINE',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentUploads(state.foodLogs),
                    const SizedBox(height: 150),
                  ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(HomeState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CALORIC.AI',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            Text(
              'Your nutrition, evolved.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                '${state.totalWater}ml',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday % 7));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayDate = firstDayOfWeek.add(Duration(days: index));
        final isToday = dayDate.day == now.day && dayDate.month == now.month;

        return Column(
          children: [
            Text(
              days[index],
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isToday ? Colors.white : AppColors.textSecondary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isToday ? Colors.white : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday ? Colors.white : AppColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  dayDate.day.toString(),
                  style: GoogleFonts.outfit(
                    color: isToday ? Colors.black : Colors.white70,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildChartSection(HomeState state) {
    final Map<DateTime, int> dailyTotals = {};
    for (var log in state.foodLogs) {
      final date = DateTime(log.createdAt.year, log.createdAt.month, log.createdAt.day);
      dailyTotals[date] = (dailyTotals[date] ?? 0) + log.calories;
    }

    final List<FlSpot> spots = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = DateTime(date.year, date.month, date.day);
      final total = dailyTotals[dayKey] ?? 0;
      final dailyGoal = state.profile?.calorieGoal ?? 2000.0;
      spots.add(FlSpot((6 - i).toDouble(), total.toDouble()));
    }

    final dailyGoal = state.profile?.calorieGoal ?? 2000.0;
    // Calculate maxY to ensure the goal line is visible and there's some padding
    double maxY = dailyGoal * 1.2;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y * 1.1;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY TREND',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Goal: ${dailyGoal.toInt()} kcal',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: dailyGoal / 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                        final date = now.subtract(Duration(days: (6 - value.toInt())));
                        final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7];
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            dayLabel,
                            style: GoogleFonts.outfit(
                              color: value.toInt() == 6 ? Colors.white : Colors.white38,
                              fontSize: 10,
                              fontWeight: value.toInt() == 6 ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppColors.surfaceLight.withOpacity(0.9),
                      tooltipRoundedRadius: 12,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toInt()} kcal',
                            GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              decoration: TextDecoration.none, // Explicitly fix decoration
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: dailyGoal.toDouble(),
                      color: Colors.white.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: false,
                        alignment: Alignment.topRight,
                        style: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.white,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.background,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
               // Show Smart Hydration Hub
               final state = context.read<HomeBloc>().state;
               showModalBottomSheet(
                 context: context,
                 backgroundColor: Colors.transparent,
                 builder: (context) => HydrationSheet(
                   currentWater: state.totalWater,
                   waterGoal: state.profile?.waterGoal ?? 2500, // Pass dynamic goal if available
                 ),
               );
            },
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop_outlined, size: 20, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Text(
                    'WATER',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumButton(
            text: 'MANUAL',
            onPressed: () => _showManualLogSheet(context),
            icon: Icons.add_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUploads(List<FoodLog> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('No entries for today', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: logs.map((log) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _recentItem(log),
      )).toList(),
    );
  }

  Widget _recentItem(FoodLog log) {
    final timeStr = DateFormat('hh:mma').format(log.createdAt).toLowerCase();
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: log.imageUrl != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(log.imageUrl!, fit: BoxFit.cover),
                )
              : const Icon(Icons.restaurant_menu_rounded, color: Colors.white24, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.foodName.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${log.calories}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'KCAL',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showManualLogSheet(BuildContext context) {
    final nameController = TextEditingController();
    final calorieController = TextEditingController();
    final proteinController = TextEditingController();
    final carbController = TextEditingController();
    final fatController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 32,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceLight, AppColors.background],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOG MEAL',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildInput(nameController, 'FOOD NAME', 'e.g. Chicken Salad', Icons.restaurant_menu),
              const SizedBox(height: 16),
              _buildInput(calorieController, 'CALORIES', 'e.g. 450', Icons.local_fire_department, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _buildInput(proteinController, 'PROTEIN (g)', '0', Icons.fitness_center, keyboardType: TextInputType.number)),
                   const SizedBox(width: 12),
                   Expanded(child: _buildInput(carbController, 'CARBS (g)', '0', Icons.grain, keyboardType: TextInputType.number)),
                   const SizedBox(width: 12),
                   Expanded(child: _buildInput(fatController, 'FAT (g)', '0', Icons.opacity, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 32),
              PremiumButton(
                text: 'ADD TO LOG',
                onPressed: () {
                  final name = nameController.text.trim();
                  final calories = int.tryParse(calorieController.text.trim());

                  if (name.isEmpty || calories == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid name and calories'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  context.read<HomeBloc>().add(AddFoodRequested(
                    name: name,
                    calories: calories,
                    protein: int.tryParse(proteinController.text.trim()),
                    carbs: int.tryParse(carbController.text.trim()),
                    fat: int.tryParse(fatController.text.trim()),
                  ));
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged $name 🥗'),
                      backgroundColor: AppColors.surfaceLight,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.white54, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}
