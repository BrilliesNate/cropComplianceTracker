// Renders the phone Admin Dashboard (in Afrikaans) with sample farms and saves a PNG to
// build/previews/ so the layout can be checked without signing in.
// Run: flutter test test/mobile/admin_dashboard_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cropCompliance/l10n/generated/app_localizations.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/views/dashboard/admin_dashboard_screen.dart'
    show CompanyStats;
import 'package:cropCompliance/views/mobile/mobile_admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final flutterRoot = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .parent
      .path; // …/flutter/bin/cache/dart-sdk/bin/dart
  final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$fonts/$f');
      if (!file.existsSync()) return;
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

CompanyModel _farm(String id, String name, String address, List<String> p) =>
    CompanyModel(
        id: id,
        name: name,
        address: address,
        createdAt: DateTime(2026),
        packages: p);

CompanyStats _stats(int users, int pending, int approved, int required) =>
    CompanyStats(
        userCount: users,
        totalRequiredDocTypes: required,
        documentCount: pending + approved,
        pendingDocs: pending,
        approvedDocs: approved);

UserModel _user(String company, String name) => UserModel(
    id: '$company-$name',
    email: '',
    name: name,
    role: UserRole.USER,
    companyId: company,
    createdAt: DateTime(2026));

void main() {
  testWidgets('phone admin dashboard preview', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(1080, 2400); // Galaxy S21
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final farms = [
      _farm('a', 'Louw Boerdery Dienste', 'Somerset West', ['siza_wieta']),
      _farm('b', 'Sterkwater Pakstoor', 'Ceres', ['siza_wieta']),
      _farm('c', 'Middelpos Boerdery', 'Hamlet', ['siza_wieta', 'globalgap']),
      _farm('d', 'All Terrain Agri Services',
          '31 Anthea street, Groenheuwel, Paarl', ['siza_wieta']),
      _farm('e', 'Constantia Glen', '', ['siza_wieta', 'fairtrade']),
      _farm('f', 'The Great Hills', 'Grabouw', ['ipw', 'globalgap']),
      for (var i = 0; i < 6; i++)
        _farm('x$i', 'Sample Farm ${i + 1}', 'Stellenbosch', ['siza_wieta']),
    ];
    final stats = {
      'a': _stats(4, 27, 34, 100),
      'b': _stats(1, 16, 0, 100),
      'c': _stats(2, 6, 14, 100),
      'd': _stats(0, 0, 96, 100),
      'e': _stats(3, 0, 46, 100),
      'f': _stats(12, 1, 71, 100),
      for (var i = 0; i < 6; i++) 'x$i': _stats(2, i, i * 15, 100),
    };
    final users = [
      for (final n in ['Anna', 'Ben', 'Carl', 'Dan']) _user('a', n),
      _user('b', 'Eve'),
      for (final n in ['Fay', 'Gus']) _user('c', n),
      for (final n in ['Hal', 'Ivy', 'Jo']) _user('e', n),
    ];

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('af'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
        home: MobileAdminDashboard(
          companies: farms,
          stats: stats,
          users: users,
          sortPending: {
            for (final e in stats.entries) e.key: e.value.pendingDocs
          },
          loading: false,
          refreshing: false,
          error: null,
          onRefresh: () async {},
          onOpen: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    Future<void> snap(String name) => tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final out = File('build/previews/$name.png');
          out.parent.createSync(recursive: true);
          out.writeAsBytesSync(bytes!.buffer.asUint8List());
        });

    await snap('admin_dashboard_phone');
    await tester.drag(find.byType(GridView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await snap('admin_dashboard_phone_scrolled');

    // Switch to one card per row; the choice is saved.
    await tester.tap(find.byTooltip('Wys een plaas per ry'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await snap('admin_dashboard_phone_single');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('adminDashboard.singleColumn'), isTrue);
    expect(find.byTooltip('Wys twee plase per ry'), findsOneWidget);
  });
}
