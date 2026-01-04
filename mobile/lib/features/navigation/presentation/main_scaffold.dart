import 'package:flutter/material.dart';
import 'package:caloric_mobile/features/home/presentation/pages/home_page.dart';
import 'package:caloric_mobile/features/progress/presentation/pages/progress_page.dart';
import 'package:caloric_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:caloric_mobile/features/coach/presentation/pages/coach_page.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';
import 'package:caloric_mobile/features/scan/presentation/pages/scan_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: const [
          HomePage(),
          ProgressPage(),
          CoachPage(),
          SettingsPage(),
        ],
      ), 
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: GlassCard(
            borderRadius: 32,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined),
                _buildNavItem(1, Icons.analytics_rounded, Icons.analytics_outlined),
                _buildScanNavItem(),
                _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? Colors.white : Colors.white24,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildScanNavItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanPage()),
        );
      },
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 28),
      ),
    );
  }
}
