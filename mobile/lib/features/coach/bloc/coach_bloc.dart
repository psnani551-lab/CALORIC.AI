import 'dart:io';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/repositories/data_repository.dart';
import '../../../core/services/ai_service.dart';

// MODELS
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, content, isUser, createdAt];
}

// EVENTS
abstract class CoachEvent extends Equatable {
  const CoachEvent();
  @override
  List<Object?> get props => [];
}

class SendMessageRequested extends CoachEvent {
  final String content;
  const SendMessageRequested(this.content);
  @override
  List<Object?> get props => [content];
}

class LoadHistory extends CoachEvent {}

// STATE
class CoachState extends Equatable {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? errorMessage;

  const CoachState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
  });

  CoachState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? errorMessage,
  }) {
    return CoachState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, errorMessage];
}

// BLOC
class CoachBloc extends Bloc<CoachEvent, CoachState> {
  final DataRepository _repository;
  final AiService _geminiService = AiService();

  CoachBloc(this._repository) : super(const CoachState()) {
    on<SendMessageRequested>(_onSendMessage);
    on<LoadHistory>(_onLoadHistory);

    add(LoadHistory());
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<CoachState> emit) async {
    try {
      final data = await _repository.getChatHistory();
      final history = data.map((e) => ChatMessage(
        id: e['id'],
        content: e['content'],
        isUser: e['is_user'] ?? true,
        createdAt: DateTime.parse(e['created_at']),
      )).toList();

      if (history.isNotEmpty) {
        emit(state.copyWith(messages: history));
      } else {
        _addInitialMessage(emit);
      }
    } catch (e) {
      debugPrint('CoachBloc: Load history error: $e');
      _addInitialMessage(emit);
    }
  }

  void _addInitialMessage(Emitter<CoachState> emit) {
    if (state.messages.isEmpty) {
      emit(state.copyWith(messages: [
        ChatMessage(
          id: 'initial',
          content: "Hello! I'm your AI Nutrition Coach. How can I help you reach your goals today?",
          isUser: false,
          createdAt: DateTime.now(),
        )
      ]));
    }
  }

  Future<void> _onSendMessage(SendMessageRequested event, Emitter<CoachState> emit) async {
    final userMessage = ChatMessage(
      id: DateTime.now().toIso8601String(),
      content: event.content,
      isUser: true,
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    ));

    // Persist User Message
    _repository.addChatMessage(content: event.content, isUser: true).catchError((e) => debugPrint('Coach Persist User Error: $e'));

    try {
      // 1. Prepare Deep Context
      final unifiedContext = json.encode(_repository.getUnifiedContext());
      
      final systemInstruction = "You are an expert AI Nutrition Coach. "
          "User Context: $unifiedContext. "
          "Base advice on this data. Keep answers short, punchy, and motivating.";

      // 2. Prepare History (Role Alternation: user -> assistant)
      // Gemini's Content.model corresponds to OpenAI's assistant role
      final history = state.messages
          .where((m) => 
            m.id != 'initial' && 
            !m.id.startsWith('error') && 
            m.id != userMessage.id
          )
          .map((m) => {
            'isUser': m.isUser,
            'content': m.content,
          })
          .toList();

      // 3. Call AI
      final responseText = await _geminiService.getChatResponse(
        prompt: event.content,
        systemInstruction: systemInstruction,
        history: history,
      );

      if (responseText == null || responseText.isEmpty) {
        throw Exception('AI returned empty response');
      }
      
      // 4. Update UI
      final aiResponse = ChatMessage(
        id: 'ai-${DateTime.now().toIso8601String()}',
        content: responseText.trim(),
        isUser: false,
        createdAt: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, aiResponse],
        isTyping: false,
      ));

      // 5. Persist AI Message
      await _repository.addChatMessage(content: responseText.trim(), isUser: false);

    } catch (e) {
      debugPrint('CoachBloc: AI/Context Error: $e');
      final errorMessage = ChatMessage(
        id: 'error-${DateTime.now().toIso8601String()}',
        content: "I'm having trouble connecting to your data right now. I can still chat, but my advice might be less specific.",
        isUser: false,
        createdAt: DateTime.now(),
      );
      emit(state.copyWith(
        messages: [...state.messages, errorMessage],
        isTyping: false, 
      ));
    }
  }
}
