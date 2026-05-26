import 'dart:async';
import 'dart:convert';
// dart:io is web-stubbed; File/Directory only used inside !kIsWeb guards
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show Directory, File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../models/chat_message.dart';
import '../providers/company_provider.dart';
import '../services/ai_chat_service.dart';
import '../services/app_localizations.dart';
import '../services/app_provider.dart';
import '../widgets/chat_message_bubble.dart';

/// Ava AI Chat — presented as a modal BottomSheet.
/// Voice recording is handled INLINE (not in a child widget) so that
/// _audioRecorder.start() is called directly inside the button's onPressed,
/// preserving the browser's transient user-activation context required for
/// getUserMedia() — which is why the mic permission dialog was never shown.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  static void show(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: isMobile ? 0.85 : 0.70,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => const AiChatScreen(),
      ),
    );
  }

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // ── Recording state (all inline — never delegated to a child widget) ──
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecordingVoice = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // ── Chat state ──
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProv = Provider.of<AppProvider>(context, listen: false);
      final companyProv = Provider.of<CompanyProvider>(context, listen: false);
      final l10n = AppLocalizations(appProv.locale);
      final isMock = companyProv.company.aiModel == 'mock-test';
      setState(() {
        _messages.add(ChatMessage(
          role: ChatRole.assistant,
          content: l10n.get(isMock ? 'ava_greeting_mock' : 'ava_greeting_ai'),
        ));
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  RECORDING HELPERS
  // ════════════════════════════════════════════════════════════════════════

  String _formatDuration(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  /// ⚠️ CRITICAL: This method is called DIRECTLY from the button's onPressed.
  /// Calling _audioRecorder.start() here preserves the browser's transient
  /// user-activation context so getUserMedia() shows the permission dialog.
  /// If start() is deferred to a child widget's initState(), the activation
  /// is lost and the browser silently blocks microphone access.
  Future<void> _startRecording(AppLocalizations l10n) async {
    if (_isRecordingVoice) return;
    try {
      // ⚠️ Check and request permission FIRST in a user-gesture context.
      // Calling hasPermission() here ensures the browser triggers the native mic dialog.
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('ava_mic_permission'))),
          );
        }
        return;
      }

      if (kIsWeb) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
      } else {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: '${Directory.systemTemp.path}/ava_audio_temp.m4a',
        );
      }
      if (!mounted) return;
      setState(() {
        _isRecordingVoice = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 30) _stopAndSendRecording();
      });
    } catch (e) {
      debugPrint('Mic start error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('ava_mic_permission'))),
        );
      }
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final duration = _recordSeconds;
    setState(() {
      _isRecordingVoice = false;
      _recordSeconds = 0;
    });
    try {
      final path = await _audioRecorder.stop();
      if (path == null || !mounted) return;

      Uint8List audioBytes;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(path));
        audioBytes = response.bodyBytes;
      } else {
        audioBytes = await File(path).readAsBytes();
        try {
          File(path).deleteSync();
        } catch (_) {}
      }

      final base64Audio = base64Encode(audioBytes);
      await _sendVoiceMessage(
          base64Audio, kIsWeb ? 'audio/webm' : 'audio/mp4', duration);
    } catch (e) {
      debugPrint('Error processing audio: $e');
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _recordSeconds = 0;
    });
    try {
      final path = await _audioRecorder.stop();
      if (!kIsWeb && path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════════
  //  CHAT HELPERS
  // ════════════════════════════════════════════════════════════════════════

  List<Map<String, String>> _buildHistory() {
    if (_messages.isEmpty) return [];
    // The last message is the current one being sent, so we exclude it from history
    final historyMessages = _messages.sublist(0, _messages.length - 1);
    final recent = historyMessages.length > 10
        ? historyMessages.sublist(historyMessages.length - 10)
        : historyMessages;
    return recent
        .map((m) => {
              'role': m.role == ChatRole.user ? 'user' : 'model',
              'content': m.content,
            })
        .toList();
  }

  String _parseReply(Map<String, dynamic> response, AppLocalizations l10n) {
    if (response.containsKey('error') && response['error'] != null) {
      final err = response['error'].toString().toLowerCase();
      if (err.contains('quota') ||
          err.contains('limit') ||
          err.contains('exhausted') ||
          err.contains('429')) {
        return l10n.get('ava_limit_reached');
      }
      return l10n.get('ava_error');
    }
    return response['reply']?.toString() ?? l10n.get('ava_error');
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final appProv = Provider.of<AppProvider>(context, listen: false);
    final companyProv = Provider.of<CompanyProvider>(context, listen: false);
    final l10n = AppLocalizations(appProv.locale);

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, content: text.trim()));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await AiChatService.sendMessage(
        message: text.trim(),
        companyId: companyProv.companyId,
        locale: appProv.locale.languageCode,
        aiModel: companyProv.company.aiModel,
        history: _buildHistory(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: ChatRole.assistant, content: _parseReply(response, l10n)));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: ChatRole.assistant, content: l10n.get('ava_error')));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendVoiceMessage(
      String base64Audio, String mimeType, int durationSeconds) async {
    final appProv = Provider.of<AppProvider>(context, listen: false);
    final companyProv = Provider.of<CompanyProvider>(context, listen: false);
    final l10n = AppLocalizations(appProv.locale);

    setState(() {
      _messages.add(ChatMessage(
        role: ChatRole.user,
        content: '',
        inputType: ChatInputType.voice,
        audioDurationSeconds: durationSeconds,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await AiChatService.sendVoiceNote(
        audioBase64: base64Audio,
        mimeType: mimeType,
        companyId: companyProv.companyId,
        locale: appProv.locale.languageCode,
        aiModel: companyProv.company.aiModel,
        history: _buildHistory(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: ChatRole.assistant, content: _parseReply(response, l10n)));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            role: ChatRole.assistant, content: l10n.get('ava_error')));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final companyProv = context.watch<CompanyProvider>();
    final l10n = AppLocalizations(appProv.locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final primaryColor = companyProv.currentCompany.primaryColor;
    final isMock = companyProv.company.aiModel == 'mock-test';

    return SafeArea(
      bottom: true,
      left: false,
      right: false,
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(context, l10n, primaryColor, isDark, isMock),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(l10n, primaryColor, isDark, isMock)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return _buildTypingIndicator(
                              l10n, primaryColor, isDark);
                        }
                        return ChatMessageBubble(
                          message: _messages[index],
                          primaryColor: primaryColor,
                          isDark: isDark,
                          l10n: l10n,
                        );
                      },
                    ),
            ),
            if (_messages.length <= 2)
              _buildQuickReplies(context, l10n, primaryColor, companyProv),
            _buildInputBar(context, l10n, primaryColor, isDark, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    Color primaryColor,
    bool isDark,
    bool isMock,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child:
                    Icon(Icons.auto_awesome, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get(isMock ? 'ava_title_mock' : 'ava_title_ai'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _isLoading ? l10n.get('ava_typing') : 'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isLoading
                            ? primaryColor
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: isDark ? Colors.white54 : Colors.black45),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    Color primaryColor,
    bool isDark,
    bool isMock,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 48, color: primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              l10n.get(isMock ? 'ava_greeting_mock' : 'ava_greeting_ai'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(
      AppLocalizations l10n, Color primaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: primaryColor.withValues(alpha: 0.15),
            child: Icon(Icons.auto_awesome, size: 16, color: primaryColor),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, primaryColor),
                const SizedBox(width: 4),
                _buildDot(1, primaryColor),
                const SizedBox(width: 4),
                _buildDot(2, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies(
    BuildContext context,
    AppLocalizations l10n,
    Color primaryColor,
    CompanyProvider companyProv,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = l10n.locale.languageCode == 'en';
    final cityName = companyProv.company.city?.trim().isNotEmpty == true
        ? companyProv.company.city!.trim()
        : (isEn ? 'our city' : 'nuestra ciudad');

    final chips = <String>[
      l10n.get('ava_chip_houses_sale', [cityName]),
      l10n.get('ava_chip_houses_rent', [cityName]),
      l10n.get('ava_chip_apts_sale', [cityName]),
      l10n.get('ava_chip_apts_rent', [cityName]),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chips.map((chipLabel) {
          final textColor = isDark ? Colors.white70 : primaryColor;
          final bgColor = isDark
              ? Colors.white.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.08);
          final borderColor = isDark
              ? Colors.white.withValues(alpha: 0.2)
              : primaryColor.withValues(alpha: 0.2);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(
              label: Text(chipLabel,
                  style: TextStyle(fontSize: 12, color: textColor)),
              backgroundColor: bgColor,
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () => _sendMessage(chipLabel),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    AppLocalizations l10n,
    Color primaryColor,
    bool isDark,
    bool isMobile,
  ) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom =
        8.0 + (bottomPadding > 0 ? 0 : MediaQuery.of(context).padding.bottom);

    // ── RECORDING UI ──────────────────────────────────────────────────────
    if (_isRecordingVoice) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 10, 8, safeBottom),
        decoration: BoxDecoration(
          color: isDark
              ? primaryColor.withValues(alpha: 0.12)
              : primaryColor.withValues(alpha: 0.07),
          border: Border(
            top: BorderSide(color: primaryColor.withValues(alpha: 0.25)),
          ),
        ),
        child: Row(
          children: [
            // Pulsing mic icon
            Icon(Icons.mic_rounded, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            // Live timer
            Text(
              _formatDuration(_recordSeconds),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            // Cancel
            TextButton(
              onPressed: _cancelRecording,
              child: Text(
                l10n.get('ava_record_cancel'),
                style:
                    TextStyle(color: isDark ? Colors.white54 : Colors.black45),
              ),
            ),
            // Send
            IconButton(
              icon: Icon(Icons.send_rounded, color: primaryColor, size: 22),
              onPressed: _stopAndSendRecording,
            ),
          ],
        ),
      );
    }

    // ── NORMAL INPUT BAR ──────────────────────────────────────────────────
    return Container(
      padding: EdgeInsets.only(left: 12, right: 8, top: 8, bottom: safeBottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // ⚠️ Mic button — onPressed calls _startRecording() DIRECTLY so that
          // _audioRecorder.start() → getUserMedia() runs within the browser's
          // transient user-activation context (gesture chain preserved).
          IconButton(
            icon: Icon(
              Icons.mic_none_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 22,
            ),
            tooltip: l10n.get('ava_recording'),
            onPressed: () => _startRecording(l10n),
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.get('ava_placeholder'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (text) {
                _sendMessage(text);
                _focusNode.requestFocus();
              },
            ),
          ),
          // Send button or spacer
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: _textController.text.trim().isNotEmpty
                ? IconButton(
                    icon:
                        Icon(Icons.send_rounded, color: primaryColor, size: 22),
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_textController.text),
                  )
                : const SizedBox(width: 48),
          ),
        ],
      ),
    );
  }
}
