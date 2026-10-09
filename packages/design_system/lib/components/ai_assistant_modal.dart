import 'dart:async';
import 'package:flutter/material.dart';
import 'package:models/models.dart';
import 'package:firebase_repository/firebase_repository.dart';
import 'package:services/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'glass_card.dart';

class AiAssistantModal extends StatefulWidget {
  final bool isAdmin;
  final String userName;
  final AiRepository? repository;
  final Map<String, dynamic>? clientLocation;
  final void Function(Map<String, dynamic> entity)? onEntityTap;

  const AiAssistantModal({
    super.key,
    required this.isAdmin,
    required this.userName,
    this.repository,
    this.clientLocation,
    this.onEntityTap,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isAdmin,
    required String userName,
    AiRepository? repository,
    Map<String, dynamic>? clientLocation,
    void Function(Map<String, dynamic> entity)? onEntityTap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiAssistantModal(
        isAdmin: isAdmin,
        userName: userName,
        repository: repository,
        clientLocation: clientLocation,
        onEntityTap: onEntityTap,
      ),
    );
  }

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  late final AiRepository _aiRepo;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _autoSpeak = true;
  String? _currentlySpeakingMsgId;
  String? _executingToken;

  final SpeechRecognitionProvider _speechProvider = DefaultSpeechRecognitionProvider();
  final TextToSpeechProvider _ttsProvider = DefaultTextToSpeechProvider();
  final OfflineAiService _offlineAi = OfflineAiService();
  StreamSubscription<String>? _speechSub;
  StreamSubscription<SpeechRecognitionState>? _speechStateSub;

  Timer? _autoSendTimer;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _aiRepo = widget.repository ?? LaravelAiRepository();

    // Persistent listener for incoming speech transcriptions (partial and final)
    _speechSub = _speechProvider.transcriptionStream.listen((text) {
      if (mounted && text.trim().isNotEmpty) {
        final recognizedText = text.trim();
        _autoSendTimer?.cancel();
        setState(() {
          _textController.text = recognizedText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: recognizedText.length),
          );
          _isListening = false;
        });
        _startVoiceCountdown();
      }
    });

    _speechStateSub = _speechProvider.stateStream.listen((state) {
      if (mounted) {
        final wasListening = _isListening;
        setState(() {
          _isListening = state == SpeechRecognitionState.listening;
        });

        // When speech recognition finishes (user stops talking) and text is present in input box
        if (wasListening && 
            (state == SpeechRecognitionState.idle || state == SpeechRecognitionState.processing) && 
            _textController.text.trim().isNotEmpty &&
            _countdownSeconds == 0) {
          _startVoiceCountdown();
        }
      }
    });

    // Initial greeting
    _messages.add(AiMessage(
      id: 'init_1',
      sender: AiSender.assistant,
      text: widget.isAdmin
          ? "Namaste ${widget.userName}! Main EmpTracker Admin AI Assistant hoon. Main live radar, active employees, overdue shops aur route summaries me aapki madad kar sakta hoon."
          : "Namaste ${widget.userName}! Main EmpTracker Employee AI Assistant hoon. Main aapke aaj ke assigned shops, duty attendance, next-shop recommendation aur route me madad kar sakta hoon.",
      timestamp: DateTime.now(),
      source: 'local_qwen_embedded',
    ));
  }

  void _startVoiceCountdown() {
    _autoSendTimer?.cancel();
    setState(() {
      _countdownSeconds = 3;
    });

    _autoSendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() => _countdownSeconds = 0);
        if (_textController.text.trim().isNotEmpty) {
          _sendMessage(_textController.text.trim(), fromVoice: true);
        }
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSendTimer?.cancel();
    _speechSub?.cancel();
    _speechStateSub?.cancel();
    _ttsProvider.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _speakMessage(String id, String text, String locale) async {
    setState(() => _currentlySpeakingMsgId = id);
    await _ttsProvider.speak(text, locale: locale);
  }

  Future<void> _sendMessage(String text, {bool fromVoice = false}) async {
    _autoSendTimer?.cancel();
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    setState(() {
      _countdownSeconds = 0;
    });
    _textController.clear();

    setState(() {
      _messages.add(AiMessage.user(trimmed));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiRepo.sendMessage(
        trimmed,
        clientContext: widget.clientLocation,
      );

      if (mounted) {
        AiMessage finalMsg = response;
        if (response.isError ||
            response.text.toLowerCase().contains('unauthenticated') ||
            response.text.toLowerCase().contains('unable to connect')) {
          final offlineResp = _offlineAi.handleOfflineQuery(trimmed);
          finalMsg = AiMessage(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            sender: AiSender.assistant,
            text: offlineResp.message,
            timestamp: DateTime.now(),
            source: 'local_engine',
          );
        }

        setState(() {
          _messages.add(finalMsg);
          _isLoading = false;
        });
        _scrollToBottom();

        if (_autoSpeak || fromVoice) {
          final loc = (finalMsg.text.contains(RegExp(r'[\u0900-\u097F]')) ||
                       finalMsg.text.toLowerCase().contains('hai') ||
                       finalMsg.text.toLowerCase().contains('kaha') ||
                       finalMsg.text.toLowerCase().contains('karo') ||
                       finalMsg.text.toLowerCase().contains('hain'))
              ? 'hi-IN'
              : 'en-US';
          _speakMessage(finalMsg.id, finalMsg.text, loc);
        }
      }
    } catch (e) {
      if (mounted) {
        // Phase 6: Graceful Offline AI Fallback
        final offlineResp = _offlineAi.handleOfflineQuery(trimmed);
        final newId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        setState(() {
          _messages.add(AiMessage(
            id: newId,
            sender: AiSender.assistant,
            text: offlineResp.message,
            timestamp: DateTime.now(),
            source: 'offline_local_knowledge',
          ));
          _isLoading = false;
        });
        _scrollToBottom();

        if (_autoSpeak || fromVoice) {
          final loc = (offlineResp.message.contains(RegExp(r'[\u0900-\u097F]')) ||
                       offlineResp.message.toLowerCase().contains('hai') ||
                       offlineResp.message.toLowerCase().contains('kaha'))
              ? 'hi-IN'
              : 'en-US';
          _speakMessage(newId, offlineResp.message, loc);
        }
      }
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechProvider.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      final hasPermission = await _speechProvider.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required for voice input.')),
          );
        }
        return;
      }
      setState(() => _isListening = true);
      await _speechProvider.startListening(localeId: 'hi-IN');
    }
  }

  Future<void> _confirmAction(AiMessage msg) async {
    final token = msg.confirmationToken;
    if (token == null || _executingToken != null) return;

    setState(() {
      _executingToken = token;
    });

    try {
      final result = await _aiRepo.confirmAction(token);
      final successMsg = result['message']?.toString() ?? 'Action executed successfully in database.';

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _messages[idx] = msg.copyWith(
              isConfirmed: true,
              text: "$successMsg\n✓ Verified & Committed to Database via 2-Step Authorization.",
            );
          }
          _executingToken = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msg.id);
          if (idx != -1) {
            _messages[idx] = msg.copyWith(
              isError: true,
              text: "Execution failed: ${e.toString().replaceAll('Exception: ', '')}",
            );
          }
          _executingToken = null;
        });
      }
    }
  }

  Future<void> _cancelAction(AiMessage msg) async {
    final token = msg.confirmationToken;
    if (token != null) {
      await _aiRepo.cancelAction(token);
    }

    if (mounted) {
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          _messages[idx] = msg.copyWith(
            isCancelled: true,
            text: "Action proposal cancelled by user.",
          );
        }
      });
    }
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

  List<String> get _quickPrompts {
    if (widget.isAdmin) {
      return [
        "🎙️ Voice Mode (बोलिए)",
        "👥 Active employees list",
        "📍 Live radar locations",
        "🏬 Kaunse shops 7 din se visit nahi hue?",
        "📊 Rahul ka route summarize karo",
      ];
    } else {
      return [
        "🎙️ Voice Mode (बोलिए)",
        "📍 Mere aaj ke shops",
        "⚡ Next shop recommendation",
        "🕒 Meri attendance status",
        "🗺️ Paas ke shops dikhao",
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Drag Bar & Title
          _buildHeader(isDark),

          // Quick Prompt Chips
          _buildQuickPromptChips(isDark),

          const Divider(height: 1, color: Color(0x1A64748B)),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) => _buildMessageBubble(_messages[idx], isDark),
            ),
          ),

          // Listening Live Banner
          if (_isListening) _buildListeningBanner(isDark),

          // Loading Indicator
          if (_isLoading) _buildLoadingIndicator(isDark),

          // Input Bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildListeningBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFFEF4444).withOpacity(0.12),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, color: Color(0xFFEF4444), size: 18),
          SizedBox(width: 8),
          Text(
            "🎙️ Listening... Speak now in Hindi or English (बोलिए...)",
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAdmin ? "FieldForce Admin AI" : "FieldForce Employee AI",
                      style: AppTypography.headingSmall(isDark: isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "⚡ Local-First Engine • Map & Route Intelligence",
                      style: AppTypography.bodySmall(isDark: isDark).copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _autoSpeak ? const Color(0xFF10B981) : Colors.grey,
                  size: 22,
                ),
                tooltip: _autoSpeak ? "Auto-Speak is ON (जवाब बोलकर सुनाएगा)" : "Auto-Speak is OFF",
                onPressed: () {
                  setState(() => _autoSpeak = !_autoSpeak);
                  if (!_autoSpeak) {
                    _ttsProvider.stop();
                    setState(() => _currentlySpeakingMsgId = null);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptChips(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final prompt = _quickPrompts[idx];
          return ActionChip(
            label: Text(
              prompt,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: prompt.contains("Voice Mode") ? const Color(0xFF6366F1) : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
              ),
            ),
            backgroundColor: prompt.contains("Voice Mode")
                ? const Color(0xFF6366F1).withOpacity(0.15)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            side: prompt.contains("Voice Mode")
                ? const BorderSide(color: Color(0xFF6366F1), width: 1.2)
                : BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              if (prompt.contains("Voice Mode")) {
                _toggleVoiceInput();
              } else {
                _sendMessage(prompt.replaceFirst(RegExp(r'^[^\s]+\s'), ''));
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg, bool isDark) {
    final isUser = msg.sender == AiSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6366F1),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.primaryDark
                      : msg.requiresConfirmation && !msg.isConfirmed && !msg.isCancelled
                          ? const Color(0xFFF59E0B)
                          : isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                  width: msg.requiresConfirmation && !msg.isConfirmed && !msg.isCancelled ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser
                          ? Colors.white
                          : msg.isError
                              ? Colors.redAccent
                              : isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                    ),
                  ),

                  // Structured Map Entities Chips (Phase 5)
                  if (!isUser && msg.entities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.entities.take(3).map((entity) {
                        final name = entity['name']?.toString() ?? 'Location Entity';
                        return ActionChip(
                          avatar: const Icon(Icons.location_on, size: 14, color: Color(0xFF6366F1)),
                          label: Text(
                            "View $name on Map",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                          ),
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
                          side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onPressed: () {
                            if (widget.onEntityTap != null) {
                              widget.onEntityTap!(entity);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Focusing $name on Live Map..."),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  // Interactive Action Confirmation Proposal Card (Phase 4)
                  if (msg.requiresConfirmation && !isUser) ...[
                    const SizedBox(height: 12),
                    _buildConfirmationProposalCard(msg, isDark),
                  ],

                  if (!isUser) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (msg.source != null)
                                _buildBadge(
                                  icon: Icons.bolt,
                                  text: msg.source == 'local_qwen_embedded' ? 'Local Engine' : msg.source!,
                                  color: const Color(0xFF10B981),
                                ),
                              if (msg.latencyMs > 0)
                                _buildBadge(
                                  icon: Icons.timer_outlined,
                                  text: "${msg.latencyMs.toStringAsFixed(1)} ms",
                                  color: const Color(0xFF6366F1),
                                ),
                              if (msg.toolsUsed.isNotEmpty)
                                _buildBadge(
                                  icon: Icons.build_circle_outlined,
                                  text: "${msg.toolsUsed.length} tool",
                                  color: const Color(0xFFF59E0B),
                                ),
                              if (msg.isConfirmed)
                                _buildBadge(
                                  icon: Icons.check_circle_outline,
                                  text: "Committed",
                                  color: const Color(0xFF10B981),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            if (_currentlySpeakingMsgId == msg.id) {
                              await _ttsProvider.stop();
                              if (mounted) setState(() => _currentlySpeakingMsgId = null);
                            } else {
                              if (mounted) setState(() => _currentlySpeakingMsgId = msg.id);
                              final loc = AiLanguageDetector.getTtsLocale(AiLanguageDetector.detect(msg.text));
                              await _ttsProvider.speak(msg.text, locale: loc);
                              if (mounted) setState(() => _currentlySpeakingMsgId = null);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _currentlySpeakingMsgId == msg.id
                                  ? const Color(0xFF10B981).withOpacity(0.2)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentlySpeakingMsgId == msg.id
                                    ? const Color(0xFF10B981)
                                    : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currentlySpeakingMsgId == msg.id ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                                  size: 15,
                                  color: _currentlySpeakingMsgId == msg.id ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentlySpeakingMsgId == msg.id ? "Speaking..." : "Listen (सुनें)",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _currentlySpeakingMsgId == msg.id
                                        ? const Color(0xFF10B981)
                                        : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildConfirmationProposalCard(AiMessage msg, bool isDark) {
    if (msg.isConfirmed) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Action Confirmed & Executed in Database.",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ),
          ],
        ),
      );
    }

    if (msg.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.grey, size: 18),
            SizedBox(width: 8),
            Text(
              "Action proposal cancelled.",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    final isExecutingThis = _executingToken == msg.confirmationToken;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 6),
              Text(
                "2-Step Confirmation Required",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Action: ${msg.action ?? 'Write Operation'}\nThis will modify records in the database. Please verify and confirm.",
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isExecutingThis ? null : () => _cancelAction(msg),
                child: const Text("Cancel (रद्द करें)", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isExecutingThis ? null : () => _confirmAction(msg),
                icon: isExecutingThis
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 16),
                label: Text(
                  isExecutingThis ? "Executing..." : "Confirm Action (पुष्टि करें)",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Text(
            "Synthesizing response via Local-First AI...",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_countdownSeconds > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFF6366F1).withOpacity(0.12),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, size: 16, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Voice detected • Sending in ${_countdownSeconds}s...",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _autoSendTimer?.cancel();
                        setState(() => _countdownSeconds = 0);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          "Edit Text",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _autoSendTimer?.cancel();
                        setState(() => _countdownSeconds = 0);
                        _sendMessage(_textController.text.trim(), fromVoice: true);
                      },
                      child: const Text("Send Now (भेजें)", style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      onChanged: (_) {
                        if (_countdownSeconds > 0) {
                          _autoSendTimer?.cancel();
                          setState(() => _countdownSeconds = 0);
                        }
                      },
                      onTap: () {
                        if (_countdownSeconds > 0) {
                          _autoSendTimer?.cancel();
                          setState(() => _countdownSeconds = 0);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Poochiye (Hindi, Hinglish, English)...",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.redAccent.withOpacity(0.15)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isListening
                            ? Colors.redAccent
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Colors.redAccent
                            : (isDark ? Colors.white70 : Colors.black87),
                        size: 20,
                      ),
                      tooltip: "Voice Input (Hindi/Hinglish/English)",
                      onPressed: _toggleVoiceInput,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
