import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caloric_mobile/core/theme/app_colors.dart';
import 'package:caloric_mobile/core/widgets/premium_widgets.dart';
import 'package:caloric_mobile/features/coach/bloc/coach_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.meshGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'AI COACH',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),
        body: BlocConsumer<CoachBloc, CoachState>(
          listener: (context, state) {
            _scrollToBottom();
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return _buildTypingIndicator();
                      }
                      final message = state.messages[index];
                      return _buildMessage(message);
                    },
                  ),
                ),
                _buildInput(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.blur_on_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isUser 
                  ? const LinearGradient(colors: [Colors.blueAccent, Color(0xFF6E56F8)]) 
                  : null, // AI uses GlassCard look manually or wrapped
                color: isUser ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          ),
          if (isUser) const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.blur_on_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              'Coach is analyzing...',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    // Check if keyboard is open (viewInsets.bottom > 0)
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Container(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        bottom: isKeyboardOpen ? 20 : 110, // 20 if keyboard open, 110 if closed (Nav Bar)
        top: 20
      ),
      child: GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                  cursorColor: Colors.blueAccent,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask for a diet plan...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.3), fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(), 
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.all(4),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _sendMessage,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<CoachBloc>().add(SendMessageRequested(text));
      _controller.clear();
      _scrollToBottom();
    }
  }
}
