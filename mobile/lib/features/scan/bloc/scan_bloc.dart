import 'dart:io';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:caloric_mobile/core/services/ai_service.dart';

// EVENTS
abstract class ScanEvent extends Equatable {
  const ScanEvent();
  @override
  List<Object?> get props => [];
}

class InitializeCamera extends ScanEvent {}
class CaptureRequested extends ScanEvent {}
class GalleryPickerRequested extends ScanEvent {}
class AnalysisRequested extends ScanEvent {}
class RetakeRequested extends ScanEvent {}

// STATE
enum ScanStatus { initial, loading, ready, capturing, reviewing, analyzing, success, failure }

class ScanState extends Equatable {
  final ScanStatus status;
  final CameraController? cameraController;
  final File? capturedImage;
  final Map<String, dynamic>? result;
  final String? errorMessage;

  const ScanState({
    this.status = ScanStatus.initial,
    this.cameraController,
    this.capturedImage,
    this.result,
    this.errorMessage,
  });

  ScanState copyWith({
    ScanStatus? status,
    CameraController? cameraController,
    File? capturedImage,
    Map<String, dynamic>? result,
    String? errorMessage,
  }) {
    return ScanState(
      status: status ?? this.status,
      cameraController: cameraController ?? this.cameraController,
      capturedImage: capturedImage ?? this.capturedImage,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, cameraController, capturedImage, result, errorMessage];
}

// BLOC
class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final AiService _geminiService = AiService();
  final ImagePicker _picker = ImagePicker();

  ScanBloc() : super(const ScanState()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<CaptureRequested>(_onCaptureRequested);
    on<GalleryPickerRequested>(_onGalleryPickerRequested);
    on<AnalysisRequested>(_onAnalysisRequested);
    on<RetakeRequested>(_onRetakeRequested);
  }

  Future<void> _onInitializeCamera(InitializeCamera event, Emitter<ScanState> emit) async {
    emit(state.copyWith(status: ScanStatus.loading));
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras found');

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium, // 720p is sufficient for AI
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      emit(state.copyWith(
        status: ScanStatus.ready,
        cameraController: controller,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ScanStatus.failure,
        errorMessage: 'Camera Error: $e',
      ));
    }
  }

  Future<void> _onCaptureRequested(CaptureRequested event, Emitter<ScanState> emit) async {
    if (state.cameraController == null || !state.cameraController!.value.isInitialized) return;

    try {
      emit(state.copyWith(status: ScanStatus.capturing));
      
      // Attempt to focus before capture (if supported)
      try {
        await state.cameraController!.setFocusMode(FocusMode.locked);
        await state.cameraController!.setExposureMode(ExposureMode.locked);
      } catch (_) {}

      final xFile = await state.cameraController!.takePicture();
      
      // Unlock after capture
      try {
        await state.cameraController!.setFocusMode(FocusMode.auto);
        await state.cameraController!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      final file = File(xFile.path);

      emit(state.copyWith(
        status: ScanStatus.reviewing,
        capturedImage: file,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ScanStatus.failure,
        errorMessage: 'Capture Failed: $e',
      ));
    }
  }

  Future<void> _onGalleryPickerRequested(GalleryPickerRequested event, Emitter<ScanState> emit) async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile != null) {
        emit(state.copyWith(
          status: ScanStatus.reviewing,
          capturedImage: File(xFile.path),
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ScanStatus.failure,
        errorMessage: 'Gallery Error: $e',
      ));
    }
  }

  Future<void> _onAnalysisRequested(AnalysisRequested event, Emitter<ScanState> emit) async {
    if (state.capturedImage == null) return;

    emit(state.copyWith(status: ScanStatus.analyzing));

    try {
      // 60-second timeout for slow networks
      await _analyzeImage(state.capturedImage!, emit).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('AI Request timed out. Check network.'),
      );
    } catch (e) {
      emit(state.copyWith(
        status: ScanStatus.failure,
        errorMessage: 'Analysis Failed: $e',
      ));
    }
  }

  Future<void> _analyzeImage(File image, Emitter<ScanState> emit) async {
    // Note: analyzeFoodImage now uses the upgraded gemini-2.0-flash-exp internal model
    final result = await _geminiService.analyzeFoodImage(image);
    
    if (result != null && !result.containsKey('error')) {
      emit(state.copyWith(
        status: ScanStatus.success,
        result: result,
      ));
    } else {
      emit(state.copyWith(
        status: ScanStatus.failure,
        errorMessage: 'Could not identify food. Please try again.',
      ));
    }
  }

  void _onRetakeRequested(RetakeRequested event, Emitter<ScanState> emit) {
    emit(state.copyWith(
      status: ScanStatus.ready,
      capturedImage: null,
      result: null,
    ));
  }

  @override
  Future<void> close() {
    state.cameraController?.dispose();
    return super.close();
  }
}
