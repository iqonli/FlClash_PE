import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/presentation/classic/components.dart';
import 'package:fl_clash/presentation/classic/dashboard.dart';
import 'package:fl_clash/presentation/classic/profiles.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_profiles.dart';

void main() {
  test('classic preferences round-trip without rewriting modern dashboard', () {
    final original = AppSettingProps.fromJson({
      'classicUi': true,
      'classicDashboard': ['traffic', 'mode'],
      'dashboardWidgets': ['currentOutbound', 'profiles'],
    });
    final restored = AppSettingProps.fromJson(jsonDecode(jsonEncode(original)));
    expect(restored.classicUi, isTrue);
    expect(restored.classicDashboard, ['traffic', 'mode']);
    expect(restored.dashboardWidgets, original.dashboardWidgets);
    expect(AppSettingProps.fromJson({}).classicUi, isFalse);
  });

  test(
    'legacy layout is captured before modern card identifiers are normalized',
    () {
      final restored = AppSettingProps.fromJson({
        'dashboardWidgets': [
          'networkSpeed',
          'systemProxyButton',
          'tunButton',
          'outboundMode',
          'networkDetection',
          'trafficUsage',
          'intranetIp',
        ],
      });
      expect(restored.classicDashboard, [
        'speed',
        'systemProxy',
        'tun',
        'mode',
        'networkDetection',
        'traffic',
        'network',
      ]);
      expect(restored.classicUi, isFalse);
    },
  );

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container,
    Widget page,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'editing classic cards preserves modern layout and persists hidden cards',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final hold = container.listen(appSettingProvider, (_, _) {});
      addTearDown(hold.close);
      final modern = container.read(appSettingProvider).dashboardWidgets;
      await pump(tester, container, const ClassicDashboardEditor());
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      expect(
        container.read(appSettingProvider).classicDashboard.contains('speed'),
        isFalse,
      );
      expect(container.read(appSettingProvider).dashboardWidgets, modern);
      final json =
          jsonDecode(jsonEncode(container.read(appSettingProvider)))
              as Map<String, dynamic>;
      expect(
        AppSettingProps.fromJson(json).classicDashboard.contains('speed'),
        isFalse,
      );
    },
  );

  testWidgets('profile selection uses current profile provider', (
    tester,
  ) async {
    final profiles = [
      Profile(
        id: 1,
        label: 'First',
        autoUpdateDuration: const Duration(days: 1),
      ),
      Profile(
        id: 2,
        label: 'Second',
        autoUpdateDuration: const Duration(days: 1),
      ),
    ];
    final container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(() => TestProfiles(profiles))],
    );
    addTearDown(container.dispose);
    final hold = container.listen(currentProfileIdProvider, (_, _) {});
    addTearDown(hold.close);
    await pump(tester, container, const ClassicProfiles());
    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(container.read(currentProfileIdProvider), 2);
  });

  testWidgets('unsaved profile edits require an explicit discard decision', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await pump(
      tester,
      container,
      const ClassicPage(title: 'Profiles', body: SizedBox()),
    );
    final context = tester.element(find.byType(ClassicPage));
    classicPush<void>(context, const ClassicProfileForm());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved'), findsOneWidget);
  });
}
