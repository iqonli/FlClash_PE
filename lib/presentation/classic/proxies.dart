import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/card.dart' show selectGroupProxy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components.dart';

class ClassicProxies extends ConsumerStatefulWidget {
  const ClassicProxies({super.key});
  @override
  ConsumerState<ClassicProxies> createState() => _ClassicProxiesState();
}

class _ClassicProxiesState extends ConsumerState<ClassicProxies> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _tabsKey = GlobalKey<_ClassicGroupTabsState>();
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
        await action.delayTestPageGroup(
          groups.any((g) => g.name == _group) ? _group! : groups.first.name,
        );
      } else {
        await action.delayTestGroups(groups);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
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
        ? _ClassicGroupTabs(
            key: _tabsKey,
            groups: groups,
            selected: _group,
            onSelected: (name) {
              _group = name;
              ref
                  .read(proxiesActionProvider.notifier)
                  .updateCurrentGroupName(name);
            },
          )
        : CustomScrollView(
            controller: _scroll,
            slivers: [
              for (final group in groups) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _ProxyGridSliver(group: group),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 104)),
            ],
          );
    return ClassicPage(
      title: l.proxies,
      actions: [
        if (tab)
          IconButton(
            tooltip: l.scrollToSelected,
            icon: const Icon(Icons.adjust),
            onPressed: () {
              final tabs = _tabsKey.currentState;
              if (tabs != null) {
                tabs.locate(
                  ref.read(selectedProxyNameProvider(tabs.activeGroupName)),
                );
              }
            },
          ),
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

class _ClassicGroupTabs extends ConsumerStatefulWidget {
  const _ClassicGroupTabs({
    super.key,
    required this.groups,
    required this.selected,
    required this.onSelected,
  });
  final List<Group> groups;
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  ConsumerState<_ClassicGroupTabs> createState() => _ClassicGroupTabsState();
}

class _ClassicGroupTabsState extends ConsumerState<_ClassicGroupTabs>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  final _scrolls = <String, ScrollController>{};
  String get activeGroupName => widget.groups[_controller.index].name;
  ScrollController _scrollOf(String name) =>
      _scrolls.putIfAbsent(name, ScrollController.new);
  void locate(String? selected) {
    final group = widget.groups[_controller.index];
    final index = group.all.indexWhere((proxy) => proxy.name == selected);
    final scroll = _scrollOf(group.name);
    if (index < 0 || !scroll.hasClients) return;
    final style = ref.read(proxiesStyleSettingProvider);
    final width = context.size?.width ?? MediaQuery.sizeOf(context).width;
    final columns = ((width - 16) / _columnWidth(style.layout)).floor().clamp(
      1,
      8,
    );
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0);
    final offset =
        16 + (index ~/ columns) * (_cardHeight(style.cardType) * scale + 8);
    scroll.animateTo(
      offset.clamp(0, scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _controller = TabController(
      length: widget.groups.length,
      vsync: this,
      initialIndex: widget.groups
          .indexWhere((g) => g.name == widget.selected)
          .clamp(0, widget.groups.length - 1),
    );
    _controller.addListener(_changed);
  }

  void _changed() {
    if (!_controller.indexIsChanging) {
      widget.onSelected(widget.groups[_controller.index].name);
    }
  }

  @override
  void didUpdateWidget(covariant _ClassicGroupTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groups.length != widget.groups.length ||
        oldWidget.groups.indexed.any(
          (entry) => entry.$2.name != widget.groups[entry.$1].name,
        )) {
      _controller.removeListener(_changed);
      _controller.dispose();
      _create();
    }
  }

  @override
  void dispose() {
    for (final scroll in _scrolls.values) {
      scroll.dispose();
    }
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TabBar(
        controller: _controller,
        isScrollable: true,
        tabs: [for (final group in widget.groups) Tab(text: group.name)],
      ),
      Expanded(
        child: TabBarView(
          controller: _controller,
          children: [
            for (final group in widget.groups)
              CustomScrollView(
                key: PageStorageKey(group.name),
                controller: _scrollOf(group.name),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 104),
                    sliver: _ProxyGridSliver(group: group),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}

class _ProxyGridSliver extends ConsumerWidget {
  const _ProxyGridSliver({required this.group});
  final Group group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(proxiesStyleSettingProvider);
    final height = _cardHeight(style.cardType);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0);
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              (constraints.crossAxisExtent / _columnWidth(style.layout))
                  .floor()
                  .clamp(1, 8),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: height * scale,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => _ProxyTile(group: group, proxy: group.all[i]),
          childCount: group.all.length,
        ),
      ),
    );
  }
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
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: delayColor),
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
          ClassicRadioChoices<ProxiesSortType>(
            value: style.sortType,
            options: ProxiesSortType.values,
            label: (type) => switch (type) {
              ProxiesSortType.none => l.defaultText,
              ProxiesSortType.delay => l.delay,
              ProxiesSortType.name => l.name,
            },
            onChanged: (value) => update(style.copyWith(sortType: value)),
          ),
          SwitchListTile(
            title: Text(l.hideTimeoutProxies),
            value: style.hideTimeoutProxies,
            onChanged: (value) =>
                update(style.copyWith(hideTimeoutProxies: value)),
          ),
          ListTile(title: Text(l.layout)),
          ClassicRadioChoices<ProxiesLayout>(
            value: style.layout,
            options: ProxiesLayout.values,
            label: (layout) => switch (layout) {
              ProxiesLayout.tight => l.tight,
              ProxiesLayout.standard => l.standard,
              ProxiesLayout.loose => l.loose,
            },
            onChanged: (value) => update(style.copyWith(layout: value)),
          ),
          ListTile(title: Text(l.size)),
          ClassicRadioChoices<ProxyCardType>(
            value: style.cardType,
            options: ProxyCardType.values,
            label: (type) => type.name,
            onChanged: (value) => update(style.copyWith(cardType: value)),
          ),
        ],
      ),
    );
  }
}

double _columnWidth(ProxiesLayout layout) => switch (layout) {
  ProxiesLayout.tight => 150,
  ProxiesLayout.standard => 180,
  ProxiesLayout.loose => 220,
};

double _cardHeight(ProxyCardType type) => switch (type) {
  ProxyCardType.compact => 76,
  ProxyCardType.standard => 96,
  ProxyCardType.loose => 116,
};
