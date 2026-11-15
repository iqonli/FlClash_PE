import 'dart:async';

import 'package:fl_clash/common/common.dart' as app;
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/profiles/preview.dart';
import 'package:fl_clash/views/profiles/extend/extend.dart';
import 'package:fl_clash/views/profiles/custom/custom.dart';
import 'package:fl_clash/views/profiles/edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components.dart';

class ClassicProfiles extends ConsumerStatefulWidget {
  const ClassicProfiles({super.key});
  @override
  ConsumerState<ClassicProfiles> createState() => _ClassicProfilesState();
}

class _ClassicProfilesState extends ConsumerState<ClassicProfiles> {
  bool _updating = false;
  Future<void> _run(Future<void> Function() task) async {
    try {
      await task();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _updateAll() async {
    if (_updating) return;
    setState(() => _updating = true);
    final failures = <String>[];
    try {
      for (final profile in [...ref.read(profilesProvider)]) {
        if (profile.type != ProfileType.url) continue;
        try {
          await ref
              .read(profilesActionProvider.notifier)
              .updateProfile(profile, showLoading: true);
        } catch (error) {
          failures.add('${profile.realLabel}: $error');
        }
      }
      if (mounted && failures.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).update),
            content: SingleChildScrollView(
              child: SelectableText(failures.join('\n\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).close),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l.importFromLink),
              leading: const Icon(Icons.link),
              onTap: () => Navigator.pop(context, 'url'),
            ),
            ListTile(
              title: Text(l.file),
              leading: const Icon(Icons.file_open),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            ListTile(
              title: Text(l.qrcode),
              leading: const Icon(Icons.qr_code),
              onTap: () => Navigator.pop(context, 'qr'),
            ),
            ListTile(
              title: Text(l.custom),
              leading: const Icon(Icons.edit_note),
              onTap: () => Navigator.pop(context, 'custom'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final action = ref.read(profilesActionProvider.notifier);
    switch (choice) {
      case 'url':
        await classicPush<void>(context, const ClassicProfileForm());
      case 'file':
        await _run(action.addProfileFormFile);
      case 'qr':
        if (app.system.isDesktop) {
          await _run(action.addProfileFormQrCode);
        } else {
          final url = await classicPush<String>(context, const ScanPage());
          if (url != null) await _run(() => action.addProfileFromLink(url));
        }
      case 'custom':
        final profile = Profile.custom();
        action.putProfile(profile);
        await classicPush<void>(
          context,
          CustomProfileView(profileId: profile.id, isNew: true),
        );
    }
  }

  Future<void> _menu(Profile profile, String choice) async {
    final l = AppLocalizations.of(context);
    final action = ref.read(profilesActionProvider.notifier);
    switch (choice) {
      case 'edit':
        await classicPush<void>(context, ClassicProfileForm(profile: profile));
      case 'preview':
        await classicPush<void>(context, PreviewProfileView(profile: profile));
      case 'extend':
        await classicPush<void>(
          context,
          profile.type == ProfileType.custom
              ? CustomProfileView(profileId: profile.id)
              : ExtendView(profileId: profile.id),
        );
      case 'content':
        await classicPush<void>(context, EditProfileView(profile: profile));
      case 'update':
        await _run(() => action.updateProfile(profile, showLoading: true));
      case 'delete':
        final users = await action.providerUsers(profile);
        if (!mounted) return;
        final confirmed = await classicConfirm(
          context,
          title: l.tip,
          message: users.isEmpty
              ? l.deleteTip(l.profile)
              : l.providerInUse(
                  profile.realLabel,
                  users.map((p) => p.realLabel).join(', '),
                ),
          cancel: l.cancel,
          confirm: l.delete,
        );
        if (confirmed == true) {
          await _run(() => action.deleteProfile(profile.id));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profiles = ref.watch(profilesProvider);
    final selected = ref.watch(currentProfileIdProvider);
    return ClassicPage(
      title: l.profiles,
      actions: [
        IconButton(
          tooltip: l.update,
          onPressed: _updating ? null : _updateAll,
          icon: _updating
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        ),
        IconButton(
          tooltip: l.profilesSort,
          icon: const Icon(Icons.sort),
          onPressed: () =>
              classicPush<void>(context, const ClassicProfileSort()),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l.addProfile),
      ),
      body: profiles.isEmpty
          ? Center(child: Text(l.nullProfileDesc))
          : LayoutBuilder(
              builder: (context, size) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                itemCount: profiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (size.maxWidth / 320).floor().clamp(1, 6),
                  mainAxisExtent:
                      200 *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0),
                  mainAxisSpacing: classicGap,
                  crossAxisSpacing: classicGap,
                ),
                itemBuilder: (context, i) {
                  final profile = profiles[i];
                  final current = profile.id == selected;
                  final colors = Theme.of(context).colorScheme;
                  final info = profile.subscriptionInfo;
                  return Card.outlined(
                    margin: EdgeInsets.zero,
                    color: current
                        ? colors.secondaryContainer
                        : colors.surfaceContainerLow,
                    shape: classicCardShape.copyWith(
                      side: BorderSide(
                        color: current
                            ? colors.primary
                            : colors.surfaceContainerHighest,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () =>
                          ref.read(currentProfileIdProvider.notifier).value =
                              profile.id,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  current
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    profile.realLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: l.more,
                                  onSelected: (value) => _menu(profile, value),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(l.edit),
                                    ),
                                    PopupMenuItem(
                                      value: 'preview',
                                      child: Text(l.preview),
                                    ),
                                    PopupMenuItem(
                                      value: 'extend',
                                      child: Text(l.advancedConfig),
                                    ),
                                    PopupMenuItem(
                                      value: 'content',
                                      child: Text(l.file),
                                    ),
                                    if (profile.type == ProfileType.url)
                                      PopupMenuItem(
                                        value: 'update',
                                        child: Text(l.update),
                                      ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l.delete),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(switch (profile.type) {
                              ProfileType.url => l.remote,
                              ProfileType.file => l.local,
                              ProfileType.custom => l.custom,
                            }, style: Theme.of(context).textTheme.labelMedium),
                            if (info != null && info.usage != null) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(value: info.usage),
                              const SizedBox(height: 6),
                              Text(
                                '${classicBytes(info.upload + info.download)} / ${classicBytes(info.total)}',
                              ),
                            ],
                            const Spacer(),
                            if (profile.lastUpdateDate != null)
                              Text(
                                profile.lastUpdateDate!
                                    .toLocal()
                                    .toString()
                                    .split('.')
                                    .first,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class ClassicProfileForm extends ConsumerStatefulWidget {
  const ClassicProfileForm({super.key, this.profile});
  final Profile? profile;
  @override
  ConsumerState<ClassicProfileForm> createState() => _ClassicProfileFormState();
}

class _ClassicProfileFormState extends ConsumerState<ClassicProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile?.label ?? '');
  late final _url = TextEditingController(text: widget.profile?.url ?? '');
  late final _key = TextEditingController(
    text: widget.profile?.ageSecretKey ?? '',
  );
  late final _interval = TextEditingController(
    text: '${widget.profile?.autoUpdateDuration.inMinutes ?? 1440}',
  );
  late bool _auto = widget.profile?.autoUpdate ?? true;
  bool _busy = false;
  bool _saved = false;
  bool get _dirty =>
      _name.text != (widget.profile?.label ?? '') ||
      _url.text != (widget.profile?.url ?? '') ||
      _key.text != (widget.profile?.ageSecretKey ?? '') ||
      _auto != (widget.profile?.autoUpdate ?? true) ||
      _interval.text !=
          '${widget.profile?.autoUpdateDuration.inMinutes ?? 1440}';

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    _interval.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final action = ref.read(profilesActionProvider.notifier);
      final old = widget.profile;
      if (old == null) {
        final previousIds = {
          for (final profile in ref.read(profilesProvider)) profile.id,
        };
        await action.addProfileFromLink(
          _url.text.trim(),
          label: _name.text.trim(),
          ageSecretKey: _key.text.trim(),
        );
        for (final profile in ref.read(profilesProvider)) {
          if (!previousIds.contains(profile.id) &&
              profile.url == _url.text.trim()) {
            action.putProfile(
              profile.copyWith(
                autoUpdate: _auto,
                autoUpdateDuration: Duration(
                  minutes: int.parse(_interval.text),
                ),
              ),
            );
          }
        }
      } else {
        final current = ref.read(profileProvider(old.id));
        if (current == null) {
          throw StateError(
            AppLocalizations.of(
              context,
            ).nullTip(AppLocalizations.of(context).profile),
          );
        }
        final next = current.copyWith(
          label: _name.text.trim(),
          url: _url.text.trim(),
          ageSecretKey: _key.text.trim(),
          autoUpdate: _auto,
          autoUpdateDuration: Duration(minutes: int.parse(_interval.text)),
        );
        if (next.url != current.url ||
            next.ageSecretKey != current.ageSecretKey) {
          await action.updateProfile(next);
        } else {
          action.putProfile(next);
        }
        ref.read(setupActionProvider.notifier).autoApplyProfile();
      }
      if (mounted) {
        setState(() => _saved = true);
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final discard = await classicConfirm(
      context,
      title: l.saveChanges,
      message: l.saveChanges,
      cancel: l.cancel,
      confirm: l.discardChanges,
    );
    if (discard == true && mounted) {
      setState(() => _saved = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final url =
        widget.profile == null || widget.profile!.type == ProfileType.url;
    return PopScope<Object?>(
      canPop: _saved || (!_dirty && !_busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: ClassicPage(
        title: widget.profile == null ? l.addProfile : l.edit,
        actions: [
          IconButton(
            tooltip: l.save,
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
        body: Form(
          key: _form,
          onChanged: () => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l.name),
              ),
              if (url) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _url,
                  decoration: InputDecoration(labelText: l.url),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l.emptyTip(l.url)
                      : !value.trim().isUrl && !value.trim().isShareLink
                      ? l.invalidLinkTip
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _key,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l.ageSecretKey),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.autoUpdate),
                  value: _auto,
                  onChanged: (value) => setState(() => _auto = value),
                ),
                TextFormField(
                  controller: _interval,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.autoUpdateInterval),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                      ? l.invalidLinkTip
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ClassicProfileSort extends ConsumerWidget {
  const ClassicProfileSort({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    return ClassicPage(
      title: AppLocalizations.of(context).profilesSort,
      body: ReorderableListView.builder(
        itemCount: profiles.length,
        onReorderItem: (oldIndex, newIndex) {
          final next = [...profiles];

          next.insert(newIndex, next.removeAt(oldIndex));
          ref.read(profilesProvider.notifier).reorder(next);
        },
        itemBuilder: (_, i) => ListTile(
          key: ValueKey(profiles[i].id),
          title: Text(profiles[i].realLabel),
          leading: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}
