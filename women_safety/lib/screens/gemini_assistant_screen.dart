import 'package:flutter/material.dart';

import '../models/ai_chat_message.dart';
import '../services/config.dart';
import '../services/gemini_ai_service.dart';

class GeminiAssistantScreen extends StatefulWidget {
  const GeminiAssistantScreen({super.key});

  static const routeName = '/gemini-assistant';

  @override
  State<GeminiAssistantScreen> createState() => _GeminiAssistantScreenState();
}

class _GeminiAssistantScreenState extends State<GeminiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

  final List<String> _starterPrompts = const [
    'Make me a safety plan for going home at night',
    'What should I do if someone follows me?',
    'Help me decide if a route looks unsafe',
    'Give me SOS steps for a panic situation',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(AiChatMessage(
      role: 'assistant',
      text: 'I am Gemini Safety Assistant. Ask for safety planning, SOS steps, route guidance, or de-escalation help.',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _sending) {
      return;
    }

    final history = List<AiChatMessage>.from(_messages);

    setState(() {
      _error = null;
      _sending = true;
      _messages.add(AiChatMessage(
        role: 'user',
        text: text,
        timestamp: DateTime.now(),
      ));
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final assistantReply = await GeminiAiService.sendMessage(
        message: text,
        history: history,
        context: 'Women Safety App assistant',
        locationLabel: 'In-app chat',
        sosActive: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(AiChatMessage(
          role: 'assistant',
          text: assistantReply.reply,
          timestamp: DateTime.now(),
        ));
        _sending = false;
      });

      _scrollToBottom();

      if (assistantReply.escalationRecommended) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini recommends immediate safety action or SOS escalation.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _sending = false;
        _messages.add(AiChatMessage(
          role: 'assistant',
          text: 'I could not reach the AI service right now. Check backend connectivity and try again.',
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final featureDisabled = !Config.isGeminiAssistantEnabled;
    final disabledReason = Config.geminiAssistantDisabledReason;
    final configWarning = Config.geminiAssistantConfigWarning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Safety Assistant'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.indigo.shade600],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask for safety guidance, de-escalation, or SOS help.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gemini is configured through the backend, so the key stays off the device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                if (featureDisabled || configWarning != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    featureDisabled
                        ? (disabledReason ?? 'Enable Gemini with FEATURE_GEMINI_ASSISTANT.')
                        : configWarning!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _starterPrompts
                        .map(
                          (prompt) => ActionChip(
                            label: Text(prompt),
                            onPressed: featureDisabled || _sending
                                ? null
                                : () => _sendMessage(prompt),
                          ),
                        )
                        .toList(),
                  );
                }

                final message = _messages[index - 1];
                final isUser = message.isUser;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !featureDisabled && !_sending,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: featureDisabled
                            ? 'Enable Gemini feature flag to use chat'
                            : 'Ask Gemini for safety help...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: featureDisabled || _sending ? null : _sendMessage,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}