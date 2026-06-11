import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../profile/widgets/ai_settings_tile.dart';

class _Message {
  final String role; // 'user' | 'assistant'
  final String text;
  const _Message(this.role, this.text);
}

/// Ask-the-Rabbi AI chat with a persistent "not a psak" banner and a
/// human-Rav escape hatch under every answer.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _ai = AiService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final profile = context.read<SettingsService>().profile;

    setState(() {
      _messages.add(_Message('user', text));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();

    final result = await _ai.chat(
      profile: profile,
      history: [for (final m in _messages) (role: m.role, text: m.text)],
    );

    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.add(_Message(
        'assistant',
        result.isOk ? result.text! : '⚠️ ${result.error}',
      ));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasKey = context.select<SettingsService, bool>(
        (s) => s.profile.anthropicApiKey.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('שאל')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: scheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'תוכן לימודי בלבד — אינו פסק הלכה. לפסיקה אישית פנו לרב.',
              style: TextStyle(
                  fontSize: 12.5, color: scheme.onSecondaryContainer),
            ),
          ),
          Expanded(
            child: !hasKey && _messages.isEmpty
                ? const _KeySetupPrompt()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                        );
                      }
                      return _MessageBubble(message: _messages[i]);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'שאלו על הלכה, מנהגים, מקורות…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.arrow_upward),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == 'user';

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82),
          decoration: BoxDecoration(
            color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SelectableText(
            message.text,
            style: TextStyle(
              color: isUser ? scheme.onPrimary : scheme.onSurface,
              fontSize: 15,
            ),
          ),
        ),
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 6),
            child: Text(
              'שאלה מורכבת או אישית? פנו ישירות לרב.',
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ),
      ],
    );
  }
}

class _KeySetupPrompt extends StatelessWidget {
  const _KeySetupPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'כלי הבינה המלאכותית דורשים מפתח API של Anthropic.\n'
              'המפתח נשמר במכשיר בלבד.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => showAiKeyDialog(context),
              child: const Text('הוספת מפתח API'),
            ),
          ],
        ),
      ),
    );
  }
}
