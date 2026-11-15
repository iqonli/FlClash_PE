import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/card.dart' show selectGroupProxy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism_ui/prism_list.dart';

import 'components.dart';

class ClassicProxies extends ConsumerStatefulWidget {
  const ClassicProxies({super.key});
  @override
  ConsumerState<ClassicProxies> createState() => _ClassicProxiesState();
}

class _ClassicProxiesState extends ConsumerState<ClassicProxies> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  bool _searching = false;
  String? _group;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _test(List<Group> groups, bool tab) async {
    if (groups.isEmpty) return;
    final action = ref.read(proxiesActionProvider.notifier);
    try {
      if (tab) {
        await action.delayTestPageGroup(_group ?? groups.first.name);
      } else {
        await action.delayTestGroups(groups);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = ref.watch(proxiesStyleSettingProvider);
    final groups = ref.watch(filterGroupsStateProvider(_search.text)).value;
    final tab = style.type == ProxiesType.tab;
    final testing = ref.watch(
      pendingDelayTestsProvider.select((s) => s.isNotEmpty),
    );
    final body = groups.isEmpty
        ? Center(child: Text(l.nullTip(l.proxies)))
        : tab
        ? DefaultTabController(
            length: groups.length,
            initialIndex: (groups.indexWhere((g) => g.name == _group))
                .clamp(0, groups.length - 1),
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  onTap: (i) {
                    _group = groups[i].name;
                    ref
                        .read(proxiesActionProvider.notifier)
                        .updateCurrentGroupName(_group!);
                  },
                  tabs: [for (final group in groups) Tab(text: group.name)],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final group in groups) _GroupGrid(group: group),
                    ],
                  ),
                ),
              ],
            ),
          )
        : PrismListView.builder(
            controller: _scroll,
            itemCount: groups.length,
            estimatedItemExtent: 280,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: classicGap),
              child: _GroupGrid(group: groups[i], embedded: true),
            ),
          );
    return ClassicPage(
      title: l.proxies,
      actions: [
        IconButton(
          tooltip: l.search,
          icon: const Icon(Icons.search),
          onPressed: () => setState(() {
            _searching = !_searching;
            if (!_searching) {
              _search.clear();
              ref.read(queryProvider(QueryTag.proxies).notifier).value = '';
            }
          }),
        ),
        IconButton(
          tooltip: l.settings,
          icon: const Icon(Icons.more_vert),
          onPressed: () =>
              classicPush<void>(context, const ClassicProxySettings()),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        tooltip: l.delayTest,
        onPressed: () => testing
            ? ref.read(proxiesActionProvider.notifier).cancelDelayTests()
            : _test(groups, tab),
        child: testing ? const Icon(Icons.stop) : const Icon(Icons.bolt),
      ),
      body: Column(
        children: [
          if (_searching)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.search,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  ref.read(queryProvider(QueryTag.proxies).notifier).value =
                      value;
                  setState(() {});
                },
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.group, this.embedded = false});
  final Group group;
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    if (embedded)
      return Card.filled(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(group.name),
          subtitle: Text(group.type.name),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: _grid(context, true),
            ),
          ],
        ),
      );
    return _grid(context, false);
  }

  Widget _grid(BuildContext context, bool shrinkWrap) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 180).floor().clamp(2, 8);
      return GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 96),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 96,
        ),
        itemCount: group.all.length,
        itemBuilder: (_, i) => _ProxyTile(group: group, proxy: group.all[i]),
      );
    },
  );
}

class _ProxyTile extends ConsumerWidget {
  const _ProxyTile({required this.group, required this.proxy});
  final Group group;
  final Proxy proxy;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(selectedProxyNameProvider(group.name)) == proxy.name;
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: group.testUrl),
    );
    final pending =
        ref.watch(
          delayTestPhaseProvider(proxyName: proxy.name, testUrl: group.testUrl),
        ) !=
        null;
    final colors = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final delayColor = delay == null
        ? colors.onSurfaceVariant
        : delay <= 0
        ? colors.error
        : delay < 300
        ? Colors.green
        : delay < 800
        ? Colors.orange
        : colors.error;
    return Card.filled(
      margin: EdgeInsets.zero,
      shape: classicCardShape,
      color: selected ? colors.primaryContainer : colors.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => selectGroupProxy(
          ref,
          groupName: group.name,
          groupType: group.type,
          proxyName: proxy.name,
        ),
        onLongPress: () => ref.read(proxiesActionProvider.notifier).delayTest([
          proxy,
        ], group.testUrl),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  proxy.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      proxy.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (pending)
                    const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      delay == null
                          ? '-'
                          : delay <= 0
                          ? l.timeout
                          : '$delay ms',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: delayColor),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassicProxySettings extends ConsumerWidget {
  const ClassicProxySettings({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final style = ref.watch(proxiesStyleSettingProvider);
    void update(ProxiesStyleProps value) {
      ref.read(proxiesStyleSettingProvider.notifier).value = value;
      ref.read(proxiesActionProvider.notifier).updateGroupsDebounce();
    }

    return ClassicPage(
      title: l.settings,
      body: ListView(
        children: [
          ListTile(title: Text(l.style)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ProxiesType>(
              segments: [
                for (final type in ProxiesType.values)
                  ButtonSegment(
                    value: type,
                    label: Text(type.name),
                    icon: Icon(
                      type == ProxiesType.tab
                          ? Icons.view_carousel
                          : Icons.view_list,
                    ),
                  ),
              ],
              selected: {style.type},
              onSelectionChanged: (value) =>
                  update(style.copyWith(type: value.first)),
            ),
          ),
          ListTile(title: Text(l.sort)),
          for (final type in ProxiesSortType.values)
            RadioListTile<ProxiesSortType>(
              title: Text(switch (type) {
                ProxiesSortType.none => l.defaultText,
                ProxiesSortType.delay => l.delay,
                ProxiesSortType.name => l.name,
              }),
              value: type,
              groupValue: style.sortType,
              onChanged: (value) {
                if (value != null) update(style.copyWith(sortType: value));
              },
            ),
          SwitchListTile(
            title: Text(l.hideTimeoutProxies),
            value: style.hideTimeoutProxies,
            onChanged: (value) =>
                update(style.copyWith(hideTimeoutProxies: value)),
          ),
          ListTile(title: Text(l.size)),
          for (final type in ProxyCardType.values)
            RadioListTile<ProxyCardType>(
              title: Text(type.name),
              value: type,
              groupValue: style.cardType,
              onChanged: (value) {
                if (value != null) update(style.copyWith(cardType: value));
              },
            ),
        ],
      ),
    );
  }
}
