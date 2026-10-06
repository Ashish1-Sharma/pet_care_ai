import 'package:flutter/material.dart';
import '../../config/api.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class VetChatScreen extends StatefulWidget {
  const VetChatScreen({super.key});

  @override
  State<VetChatScreen> createState() => _VetChatScreenState();
}

class _VetChatScreenState extends State<VetChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late final ApiService _api;
  bool _isLoading = false;
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    _api = ApiService(StorageService());
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await _api.get(ApiEndpoints.chatHistory);
      if (res.data is List) {
        final list = res.data as List;
        setState(() {
          _messages.addAll(list.map((m) => _ChatMessage(
            role: m['role'] as String? ?? 'user',
            content: m['content'] as String? ?? '',
          )));
          _historyLoaded = true;
        });
        _scrollToBottom(animated: false);
      }
    } catch (_) {
      setState(() => _historyLoaded = true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await _api.post(ApiEndpoints.chat, data: {'message': text});
      final reply = res.data['message'] as String? ?? '';
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: reply));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: 'Sorry, something went wrong. Please try again.',
          isError: true,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(),
          Expanded(
            child: _historyLoaded
                ? _MessageList(
                    messages: _messages,
                    isLoading: _isLoading,
                    scrollController: _scrollController,
                    onScannerTap: () {
                      Navigator.of(context).pop();
                    },
                  )
                : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          _InputBar(
            controller: _inputController,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm, AppSpacing.sm, AppSpacing.gutter, AppSpacing.lg,
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: AppRadius.brMd,
                ),
                child: const Icon(Icons.pets_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PawDoc',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'AI Vet Assistant · Powered by AI',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: AppRadius.brPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EF5B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Message list
// ──────────────────────────────────────────────
class _MessageList extends StatelessWidget {
  final List<_ChatMessage> messages;
  final bool isLoading;
  final ScrollController scrollController;
  final VoidCallback onScannerTap;

  const _MessageList({
    required this.messages,
    required this.isLoading,
    required this.scrollController,
    required this.onScannerTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      if (messages.isEmpty) const _WelcomeBubble(),
      ...messages.map((m) => m.role == 'user'
          ? _UserBubble(message: m)
          : _AssistantBubble(message: m, onScannerTap: onScannerTap)),
      if (isLoading) const _TypingIndicator(),
    ];

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: items[i],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Welcome bubble (empty state)
// ──────────────────────────────────────────────
class _WelcomeBubble extends StatelessWidget {
  const _WelcomeBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: AppRadius.brLg,
            ),
            child: const Icon(Icons.pets_rounded, color: Colors.white, size: 36),
          ),
          AppSpacing.gapMd,
          Text(
            'Hi! I\'m PawDoc 🐾',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            'Ask me anything about your pet\'s health,\nbehavior, nutrition, or care.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: const [
              _SuggestionChip('My dog won\'t eat 🐶'),
              _SuggestionChip('Cat vomiting 🐱'),
              _SuggestionChip('Vaccination schedule 💉'),
              _SuggestionChip('Skin rash help 🔴'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip(this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final state = context.findAncestorStateOfType<_VetChatScreenState>(); // ignore: invalid_use_of_protected_member
        state?._inputController.text = label;
        state?._inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: state._inputController.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: AppColors.alpha(AppColors.primary, 0.3)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// User bubble (right-aligned, green)
// ──────────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final _ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.md),
            topRight: Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(AppRadius.md),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Assistant bubble (left-aligned, white card)
// ──────────────────────────────────────────────
class _AssistantBubble extends StatelessWidget {
  final _ChatMessage message;
  final VoidCallback onScannerTap;

  const _AssistantBubble({required this.message, required this.onScannerTap});

  bool get _mentionsScanner =>
      message.content.toLowerCase().contains('pet scanner');

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 16),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isError
                      ? AppColors.criticalityEmergencyBg
                      : AppColors.surfaceElevated,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(AppRadius.md),
                    bottomRight: Radius.circular(AppRadius.md),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.alpha(AppColors.ink, 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: message.isError
                        ? AppColors.criticalityEmergency
                        : AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ),
              // Scanner CTA when promoted
              if (_mentionsScanner) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onScannerTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.center_focus_strong_rounded,
                            color: Colors.white, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          'Try Pet Scanner',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Typing indicator
// ──────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(AppRadius.md),
              bottomLeft: Radius.circular(AppRadius.md),
              bottomRight: Radius.circular(AppRadius.md),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.alpha(AppColors.ink, 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i / 3;
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                  final scale = 1.0 + 0.5 * (1 - (2 * t - 1).abs());
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7 * scale,
                    height: 7 * scale,
                    decoration: BoxDecoration(
                      color: AppColors.alpha(AppColors.primary, 0.6),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Input bar
// ──────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          boxShadow: [
            BoxShadow(
              color: AppColors.alpha(AppColors.ink, 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about your pet…',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceSunken,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brPill,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: isLoading ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isLoading ? null : AppColors.gradientPrimary,
                  color: isLoading ? AppColors.border : null,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Data model
// ──────────────────────────────────────────────
class _ChatMessage {
  final String role;
  final String content;
  final bool isError;

  const _ChatMessage({
    required this.role,
    required this.content,
    this.isError = false,
  });
}
