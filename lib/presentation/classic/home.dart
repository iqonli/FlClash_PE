import 'package:fl_clash/common/common.dart' as app;
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/views.dart' as modern;
import 'package:fl_clash/views/theme.dart' as modern;
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/config/advanced.dart';
import 'package:fl_clash/views/backup_and_restore.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/views/access.dart';
import 'package:prism_ui/prism_ui.dart' as prism;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components.dart';
import 'dashboard.dart';
import 'proxies.dart';
import 'profiles.dart';

class ClassicHome extends ConsumerStatefulWidget {
  const ClassicHome({super.key});
  @override
  ConsumerState<ClassicHome> createState() => _ClassicHomeState();
}

class _ClassicHomeState extends ConsumerState<ClassicHome> {
  int _index = 0;
  final _visited = <int>{0};
  final _keys = List.generate(7, (_) => GlobalKey<NavigatorState>());

  void _select(int value) {
    if (value == _index) return;
    setState(() {
      _index = value;
      _visited.add(value);
    });
    ref.read(currentPageLabelProvider.notifier).toPage(switch (value) {
      0 => PageLabel.dashboard,
      1 => PageLabel.proxies,
      2 => PageLabel.profiles,
      4 || 5 => PageLabel.requests,
      6 => PageLabel.logs,
      _ => PageLabel.tools,
    });
  }

  Future<void> _back() async {
    if (await (_keys[_index].currentState?.maybePop() ?? Future.value(false)))
      return;
    if (!mounted) return;
    if (app.system.isTV && _index != 0) {
      _select(0);
      return;
    }
    await ref.read(systemActionProvider.notifier).handleClose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mobile = MediaQuery.sizeOf(context).width <= 600;
    final hasProxies = ref.watch(profilesProvider.select((s) => s.isNotEmpty));
    final logs = ref.watch(appSettingProvider.select((s) => s.openLogs));
    final labels = [
      l.dashboard,
      l.proxies,
      l.profiles,
      l.tools,
      l.requests,
      l.connections,
      l.logs,
    ];
    const icons = [
      Icons.space_dashboard,
      Icons.article,
      Icons.folder,
      Icons.construction,
      Icons.view_timeline,
      Icons.ballot,
      Icons.adb,
    ];
    final destinations = [
      0,
      if (hasProxies) 1,
      2,
      if (!mobile) ...[4, 5, if (logs) 6],
      3,
    ];
    final selected = _index == 1 && !hasProxies ? 0 : _index;
    final navSelected = destinations.contains(selected) ? selected : 3;
    final bodies = <WidgetBuilder>[
      (_) => const ClassicDashboard(),
      (_) => const ClassicProxies(),
      (_) => const ClassicProfiles(),
      (_) => ClassicTools(onSelect: _select),
      (_) => const modern.RequestsView(initialFeed: RequestFeed.recent),
      (_) => const modern.RequestsView(initialFeed: RequestFeed.live),
      (_) => const modern.LogsView(),
    ];
    final body = IndexedStack(
      index: selected,
      children: [
        for (var i = 0; i < bodies.length; i++)
          _visited.contains(i)
              ? prism.PageActivityScope(
                  isActive: i == selected,
                  child: TickerMode(
                    enabled: i == selected,
                    child: ExcludeFocus(
                      excluding: i != selected,
                      child: Navigator(
                        key: _keys[i],
                        onGenerateRoute: (_) =>
                            MaterialPageRoute(builder: bodies[i]),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
      ],
    );
    final expanded = ref.watch(
      appSettingProvider.select((s) => s.sidebarExpanded),
    );
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: Row(
          children: [
            if (!mobile)
              Material(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (!app.system.isMacOS)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.shield, size: 40),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              selectedIndex: destinations.indexOf(navSelected),
                              labelType: expanded
                                  ? NavigationRailLabelType.all
                                  : NavigationRailLabelType.none,
                              backgroundColor: Colors.transparent,
                              destinations: [
                                for (final i in destinations)
                                  NavigationRailDestination(
                                    icon: Icon(icons[i]),
                                    label: Text(labels[i]),
                                  ),
                              ],
                              onDestinationSelected: (i) =>
                                  _select(destinations[i]),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.interfaceStyle,
                        icon: const Icon(Icons.menu),
                        onPressed: () => ref
                            .read(appSettingProvider.notifier)
                            .update(
                              (s) => s.copyWith(sidebarExpanded: !expanded),
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: mobile
            ? NavigationBar(
                selectedIndex: destinations.indexOf(navSelected),
                destinations: [
                  for (final i in destinations)
                    NavigationDestination(
                      icon: Icon(icons[i]),
                      label: labels[i],
                    ),
                ],
                onDestinationSelected: (i) => _select(destinations[i]),
              )
            : null,
      ),
    );
  }
}

class ClassicTools extends ConsumerWidget {
  const ClassicTools({super.key, required this.onSelect});
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    Widget row(String label, IconData icon, Widget page) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => classicPush<void>(context, page),
    );
    return ClassicPage(
      title: l.tools,
      body: ListView(
        children: [
          ListTile(
            title: Text(l.more, style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.view_timeline),
            title: Text(l.requests),
            onTap: () => onSelect(4),
          ),
          ListTile(
            leading: const Icon(Icons.ballot),
            title: Text(l.connections),
            onTap: () => onSelect(5),
          ),
          if (ref.watch(appSettingProvider.select((s) => s.openLogs)))
            ListTile(
              leading: const Icon(Icons.adb),
              title: Text(l.logs),
              onTap: () => onSelect(6),
            ),
          row(l.resources, Icons.storage, const modern.ResourcesView()),
          const Divider(),
          ListTile(
            title: Text(
              l.settings,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text(l.language),
                children: [
                  for (final locale
                      in AppLocalizations.delegate.supportedLocales)
                    SimpleDialogOption(
                      child: Text(locale.toString()),
                      onPressed: () {
                        ref
                            .read(appSettingProvider.notifier)
                            .update(
                              (s) => s.copyWith(locale: locale.toString()),
                            );
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ),
          row(l.theme, Icons.palette_outlined, const modern.ThemeView()),
          row(
            l.backupAndRestore,
            Icons.cloud_sync_outlined,
            const BackupAndRestore(),
          ),
          if (app.system.isDesktop)
            row(l.hotkeyManagement, Icons.keyboard, const HotKeyView()),
          if (app.system.isAndroid)
            row(l.accessControl, Icons.apps, const AccessView()),
          row(l.advancedConfig, Icons.tune, const AdvancedConfigView()),
          row(l.settings, Icons.settings_outlined, const GeneralView()),
          const Divider(),
          row(l.about, Icons.info_outline, const AboutView()),
        ],
      ),
    );
  }
}
