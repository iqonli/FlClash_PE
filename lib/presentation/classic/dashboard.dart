import 'package:fl_clash/common/common.dart' as app;
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components.dart';

const _cards = ['speed', 'mode', 'traffic', 'network', 'takeover'];

class ClassicDashboard extends ConsumerStatefulWidget {
  const ClassicDashboard({super.key});
  @override
  ConsumerState<ClassicDashboard> createState() => _ClassicDashboardState();
}

class _ClassicDashboardState extends ConsumerState<ClassicDashboard> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(setupActionProvider.notifier)
          .setRunning(!ref.read(isStartProvider));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() =>
      classicPush<void>(context, const ClassicDashboardEditor());

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final running = ref.watch(isStartProvider);
    final profile = ref.watch(currentProfileProvider);
    final order = ref
        .watch(appSettingProvider.select((s) => s.classicDashboard))
        .where(_cards.contains)
        .toList();
    return ClassicPage(
      title: l.dashboard,
      actions: [
        IconButton(
          tooltip: l.editDashboard,
          onPressed: _edit,
          icon: const Icon(Icons.edit),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy || profile == null ? null : _toggle,
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(running ? Icons.stop : Icons.play_arrow),
        label: Text(
          _busy
              ? l.connecting
              : running
              ? l.stop
              : l.start,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 840
              ? 3
              : constraints.maxWidth > 560
              ? 2
              : 1;
          final width =
              (constraints.maxWidth - 32 - classicGap * (columns - 1)) /
              columns;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
            child: Wrap(
              spacing: classicGap,
              runSpacing: classicGap,
              children: [
                for (final id in order)
                  SizedBox(
                    width: id == 'speed' && columns > 1
                        ? width * 2 + classicGap
                        : width,
                    child: RepaintBoundary(child: _DashboardCard(id: id)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends ConsumerWidget {
  const _DashboardCard({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.headlineSmall;
    switch (id) {
      case 'speed':
        final traffic = ref.watch(trafficsProvider).list;
        final latest = traffic.isEmpty ? const Traffic() : traffic.last;
        return ClassicCard(
          title: l.networkSpeed,
          icon: Icons.speed,
          child: Row(
            children: [
              Expanded(
                child: Text('↑ ${classicBytes(latest.up)}/s', style: style),
              ),
              Expanded(
                child: Text('↓ ${classicBytes(latest.down)}/s', style: style),
              ),
            ],
          ),
        );
      case 'traffic':
        final total = ref.watch(totalTrafficProvider);
        return ClassicCard(
          title: l.trafficUsage,
          icon: Icons.data_usage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('↑ ${classicBytes(total.up)}', style: style),
              Text('↓ ${classicBytes(total.down)}', style: style),
            ],
          ),
        );
      case 'mode':
        final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
        return ClassicCard(
          title: l.outboundMode,
          icon: Icons.alt_route,
          child: Wrap(
            spacing: 8,
            children: [
              for (final value in Mode.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: value == mode,
                  onSelected: (_) =>
                      ref.read(setupActionProvider.notifier).changeMode(value),
                ),
            ],
          ),
        );
      case 'network':
        final ip = ref.watch(localIpProvider);
        final profile = ref.watch(currentProfileProvider);
        return ClassicCard(
          title: l.intranetIP,
          icon: Icons.devices,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(ip ?? l.connecting, style: style),
              const SizedBox(height: 8),
              Text(profile?.realLabel ?? l.nullProfileDesc),
            ],
          ),
        );
      default:
        final tun = ref.watch(
          patchClashConfigProvider.select((s) => s.tun.enable),
        );
        final proxy = ref.watch(
          networkSettingProvider.select((s) => s.systemProxy),
        );
        final vpn = ref.watch(vpnSettingProvider.select((s) => s.enable));
        return ClassicCard(
          title: app.system.isAndroid ? 'VPN' : l.network,
          icon: Icons.security,
          child: Column(
            children: [
              if (app.system.isAndroid)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('VPN'),
                  value: vpn,
                  onChanged: (value) => ref
                      .read(vpnSettingProvider.notifier)
                      .update((s) => s.copyWith(enable: value)),
                )
              else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('TUN'),
                  value: tun,
                  onChanged: (value) => ref
                      .read(patchClashConfigProvider.notifier)
                      .update((s) => s.copyWith.tun(enable: value)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.systemProxy),
                  value: proxy,
                  onChanged: (value) => ref
                      .read(networkSettingProvider.notifier)
                      .update((s) => s.copyWith(systemProxy: value)),
                ),
              ],
            ],
          ),
        );
    }
  }
}

class ClassicDashboardEditor extends ConsumerWidget {
  const ClassicDashboardEditor({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(
      appSettingProvider.select((s) => s.classicDashboard),
    );
    final selected = saved.where(_cards.contains).toSet();
    final order = [
      ...saved.where(_cards.contains).toSet(),
      ..._cards.where((id) => !selected.contains(id)),
    ];
    final labels = {
      'speed': l.networkSpeed,
      'mode': l.outboundMode,
      'traffic': l.trafficUsage,
      'network': l.intranetIP,
      'takeover': l.network,
    };
    void save(List<String> value) => ref
        .read(appSettingProvider.notifier)
        .update((s) => s.copyWith(classicDashboard: value));
    return ClassicPage(
      title: l.classicDashboardLayout,
      body: ReorderableListView.builder(
        itemCount: order.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          final next = [...order];
          final item = next.removeAt(oldIndex);
          next.insert(newIndex, item);
          save(next.where(selected.contains).toList());
        },
        itemBuilder: (_, i) => CheckboxListTile(
          key: ValueKey(order[i]),
          title: Text(labels[order[i]]!),
          value: selected.contains(order[i]),
          onChanged: (value) => save(
            value == true
                ? [...selected, order[i]]
                : selected.where((id) => id != order[i]).toList(),
          ),
        ),
      ),
    );
  }
}
