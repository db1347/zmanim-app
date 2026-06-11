import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_profile.dart';
import '../../../services/settings_service.dart';

/// Profile tile for managing the on-device Anthropic API key.
class AiSettingsTile extends StatelessWidget {
  const AiSettingsTile({
    super.key,
    required this.profile,
    required this.onUpdate,
  });

  final UserProfile profile;
  final Future<void> Function(UserProfile) onUpdate;

  @override
  Widget build(BuildContext context) {
    final hasKey = profile.anthropicApiKey.isNotEmpty;
    return ListTile(
      leading: const Icon(Icons.key),
      title: const Text('מפתח API של Anthropic'),
      subtitle: Text(hasKey
          ? 'מוגדר (${_mask(profile.anthropicApiKey)}) · נשמר במכשיר בלבד'
          : 'לא מוגדר — נדרש ל«שאל» ולסורק הברכות'),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => showAiKeyDialog(context),
    );
  }

  static String _mask(String key) => key.length <= 8
      ? '••••'
      : '${key.substring(0, 7)}…${key.substring(key.length - 4)}';
}

/// Shared dialog to enter/replace/clear the API key.
Future<void> showAiKeyDialog(BuildContext context) async {
  final settings = context.read<SettingsService>();
  final controller =
      TextEditingController(text: settings.profile.anthropicApiKey);

  try {
    await _showKeyDialog(context, settings, controller);
  } finally {
    controller.dispose();
  }
}

Future<void> _showKeyDialog(
  BuildContext context,
  SettingsService settings,
  TextEditingController controller,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('מפתח API של Anthropic'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'מפעיל את «שאל» ואת סורק הברכות. המפתח לא יוצא מהמכשיר '
            'מלבד לצורך הקריאה ל־Anthropic API.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'sk-ant-…',
              hintTextDirection: TextDirection.ltr,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await settings
                .update(settings.profile.copyWith(anthropicApiKey: ''));
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('ניקוי'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: () async {
            await settings.update(settings.profile
                .copyWith(anthropicApiKey: controller.text.trim()));
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('שמירה'),
        ),
      ],
    ),
  );
}
