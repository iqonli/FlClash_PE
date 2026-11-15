import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/font_family.dart';
import 'package:prism_ui/prism_ui.dart' as prism;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components.dart';

class ClassicAppearance extends ConsumerWidget {
  const ClassicAppearance({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(themeSettingProvider);
    return ClassicPage(
      title: l.theme,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ListTile(
            title: Text(l.interfaceStyle),
            subtitle: Text(l.classicInterface),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final modern = await classicConfirm(
                context,
                title: l.interfaceStyle,
                message: l.modernInterface,
                cancel: l.cancel,
                confirm: l.confirm,
              );
              if (modern == true && context.mounted) {
                ref
                    .read(appSettingProvider.notifier)
                    .update((s) => s.copyWith(classicUi: false));
              }
            },
          ),
          const Divider(),
          ListTile(title: Text(l.themeMode)),
          ClassicRadioChoices<prism.ThemeMode>(
            value: settings.themeMode,
            options: prism.ThemeMode.values,
            label: (mode) => switch (mode) {
              prism.ThemeMode.system => l.auto,
              prism.ThemeMode.light => l.light,
              prism.ThemeMode.dark => l.dark,
            },
            onChanged: (value) => ref
                .read(themeSettingProvider.notifier)
                .update((s) => s.copyWith(themeMode: value)),
          ),
          SwitchListTile(
            title: Text(l.pureBlack),
            value: settings.pureBlack,
            onChanged: (value) => ref
                .read(themeSettingProvider.notifier)
                .update((s) => s.copyWith(pureBlack: value)),
          ),
          const Divider(),
          ListTile(title: Text(l.themeColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in [
                  Colors.blue,
                  Colors.indigo,
                  Colors.purple,
                  Colors.pink,
                  Colors.red,
                  Colors.orange,
                  Colors.green,
                  Colors.teal,
                ])
                  Semantics(
                    label:
                        '${l.themeColor} ${color.toARGB32().toRadixString(16)}',
                    selected: settings.primaryColor == color.toARGB32(),
                    button: true,
                    child: IconButton.filled(
                      tooltip: color.toARGB32().toRadixString(16),
                      style: IconButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => ref
                          .read(themeSettingProvider.notifier)
                          .update(
                            (s) => s.copyWith(primaryColor: color.toARGB32()),
                          ),
                      icon: Icon(
                        settings.primaryColor == color.toARGB32()
                            ? Icons.check
                            : Icons.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            title: Text(l.defaultText),
            leading: const Icon(Icons.restart_alt),
            onTap: () => ref
                .read(themeSettingProvider.notifier)
                .update((s) => s.copyWith(primaryColor: null)),
          ),
          const Divider(),
          ListTile(
            title: Text(l.fontFamily),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => classicPush<void>(context, const FontFamilyView()),
          ),
          SwitchListTile(
            title: Text(l.textScale),
            value: settings.textScale.enable,
            onChanged: (value) => ref
                .read(themeSettingProvider.notifier)
                .update((s) => s.copyWith.textScale(enable: value)),
          ),
          if (settings.textScale.enable)
            Slider(
              value: settings.textScale.scale.clamp(0.8, 2.0),
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${settings.textScale.scale.toStringAsFixed(1)}×',
              onChanged: (value) => ref
                  .read(themeSettingProvider.notifier)
                  .update((s) => s.copyWith.textScale(scale: value)),
            ),
        ],
      ),
    );
  }
}
