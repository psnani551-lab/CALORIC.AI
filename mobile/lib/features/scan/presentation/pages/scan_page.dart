import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caloric_mobile/features/scan/bloc/scan_bloc.dart';
import 'package:caloric_mobile/features/scan/presentation/widgets/nutrition_result_sheet.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScanBloc()..add(InitializeCamera()),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<ScanBloc, ScanState>(
          listener: (context, state) {
            if (state.status == ScanStatus.success) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => NutritionResultSheet(result: state.result!),
              );
            } else if (state.status == ScanStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Scan Failed: ${state.errorMessage}'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // 1. Camera Preview or Black Screen
                _buildCameraPreview(state),

                // 2. Overlays
                if (state.status == ScanStatus.ready || state.status == ScanStatus.capturing)
                  _buildScanningOverlay(),

                // 3. Review Image (if reviewing)
                if (state.capturedImage != null && state.status.index >= ScanStatus.reviewing.index)
                   Positioned.fill(child: Image.file(state.capturedImage!, fit: BoxFit.cover)),

                // 4. Top Controls (Close)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                           GestureDetector(
                             onTap: () => Navigator.pop(context),
                             child: GlassCard(
                               borderRadius: 30,
                               padding: const EdgeInsets.all(8),
                               child: const Icon(Icons.close, color: Colors.white),
                             ),
                           ),
                           const Spacer(),
                           if (state.status == ScanStatus.analyzing)
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                               child: Text("ANALYZING...", style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                             ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Bottom Controls
                Positioned(
                  bottom: 50, left: 0, right: 0,
                  child: state.status == ScanStatus.reviewing || state.status == ScanStatus.analyzing
                    ? _buildReviewControls(context, state)
                    : _buildCaptureControls(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraPreview(ScanState state) {
    if (state.cameraController == null || !state.cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return SizedBox.expand(
      child: CameraPreview(state.cameraController!),
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(), _corner()]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_corner(), _corner()]),
          ],
        ),
      ),
    );
  }

  Widget _corner() {
    return Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white24));
  }

  Widget _buildCaptureControls(BuildContext context, ScanState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => context.read<ScanBloc>().add(GalleryPickerRequested()),
          child: const Icon(Icons.photo_library, color: Colors.white, size: 30),
        ),
        GestureDetector(
          onTap: () {
            if (state.status == ScanStatus.ready) {
              context.read<ScanBloc>().add(CaptureRequested());
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 30), // Balance spacing
      ],
    );
  }

  Widget _buildReviewControls(BuildContext context, ScanState state) {
    if (state.status == ScanStatus.analyzing) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => context.read<ScanBloc>().add(RetakeRequested()),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 30,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: () => context.read<ScanBloc>().add(AnalysisRequested()),
          child: CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 30,
            child: const Icon(Icons.check, color: Colors.black, size: 30),
          ),
        ),
      ],
    );
  }
}
