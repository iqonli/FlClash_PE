import 'package:fl_clash/pages/home.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/ui/ui.dart' as prism;
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'classic/home.dart';

class PresentationHome extends ConsumerWidget {
  const PresentationHome({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(appSettingProvider.select((s) => s.classicUi))
      ? const ClassicHome()
      : const HomePage();
}

class ClassicMaterialHost extends ConsumerWidget {
  const ClassicMaterialHost({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingProvider);
    final brightness = ref.watch(currentBrightnessProvider);
    final seed = settings.primaryColor == null
        ? ref.watch(dynamicColorProvider).accentColor
        : Color(settings.primaryColor!);
    var colors = material.ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    if (settings.pureBlack && brightness == Brightness.dark) {
      colors = colors.copyWith(surface: const Color(0xff000000));
    }
    return material.Theme(
      data: material.ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        fontFamily: settings.fontFamily,
        navigationBarTheme: const material.NavigationBarThemeData(
          height: 80,
          elevation: 3,
          labelBehavior: material.NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
      child: material.ScaffoldMessenger(child: child),
    );
  }
}

class InterfaceStyleItem extends ConsumerWidget {
  const InterfaceStyleItem({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classic = ref.watch(appSettingProvider.select((s) => s.classicUi));
    final l = AppLocalizations.of(context);
    return prism.ListItem<bool>.options(
      title: Text(l.interfaceStyle),
      value: classic,
      options: const [false, true],
      textBuilder: (value) => value ? l.classicInterface : l.modernInterface,
      onChanged: (value) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
        ref
            .read(appSettingProvider.notifier)
            .update((s) => s.copyWith(classicUi: value));
      },
    );
  }
}
