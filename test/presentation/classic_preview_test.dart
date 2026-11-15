import 'dart:io';
import 'dart:ui' as ui;

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/presentation/classic/home.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_profiles.dart';

void main() {
  setUpAll(() async {
    final file = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
    if (await file.exists()) {
      final loader = FontLoader('ClassicPreviewSans')
        ..addFont(Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
    }
  });
  for (final width in [412.0, 1280.0]) {
    testWidgets('classic shell navigation and rendering at $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const profile = Profile(
        id: 1,
        label: 'Sample subscription',
        autoUpdateDuration: Duration(days: 1),
        selectedMap: {'Proxy': 'Alpha'},
      );
      final container = ProviderContainer(
        overrides: [
          profilesProvider.overrideWith(() => TestProfiles([profile])),
          currentProfileIdProvider.overrideWithBuild((_, _) => 1),
          appSettingProvider.overrideWithBuild(
            (_, _) => const AppSettingProps(
              classicUi: true,
              classicDashboard: ['speed', 'mode', 'traffic', 'network'],
            ),
          ),
          groupsProvider.overrideWithBuild(
            (_, _) => [
              const Group(
                name: 'Proxy',
                hidden: false,
                type: GroupType.Selector,
                all: [
                  Proxy(name: 'Alpha', type: 'Shadowsocks'),
                  Proxy(name: 'Beta', type: 'VLESS'),
                  Proxy(name: 'Gamma', type: 'Trojan'),
                  Proxy(name: 'Delta', type: 'Hysteria2'),
                ],
              ),
            ],
          ),
        ],
      );
      globalState.container = container;
      addTearDown(container.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'ClassicPreviewSans',
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              navigationBarTheme: const NavigationBarThemeData(height: 80),
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.delegate.supportedLocales,
            home: RepaintBoundary(key: boundary, child: const ClassicHome()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('test-output/classic-${width.toInt()}-$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('dashboard');
      final navigation = find.byType(
        width <= 600 ? NavigationBar : NavigationRail,
      );
      await tester.tap(
        find.descendant(of: navigation, matching: find.text('Proxies')).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('proxies');
      await tester.tap(
        find.descendant(of: navigation, matching: find.text('Profiles')).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sample subscription'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('profiles');
      expect(container.read(appSettingProvider).classicUi, isTrue);
      expect(container.read(currentProfileIdProvider), 1);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
