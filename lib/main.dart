import 'dart:async';

import 'package:cropCompliance/core/navigation/app_navigator.dart';
import 'package:cropCompliance/core/offline/connectivity_service.dart';
import 'package:cropCompliance/core/offline/offline_banner.dart';
import 'package:cropCompliance/core/offline/upload_outbox.dart';
import 'package:cropCompliance/providers/audit_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/route_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'core/services/firestore_service.dart';
import 'core/services/push_notification_service.dart';
import 'videoAnimation.dart';
import 'firebase_options.dart';
import 'routes/router.dart';
import 'providers/auth_provider.dart';
import 'providers/document_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';
import 'core/constants/route_constants.dart';

void main() async {
  final boot = Stopwatch()..start();
  print('⏱️  [Boot] main() START');

  WidgetsFlutterBinding.ensureInitialized();
  print('⏱️  [Boot] flutter binding ready: ${boot.elapsedMilliseconds} ms');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('⏱️  [Boot] firebase initialized: ${boot.elapsedMilliseconds} ms');

  // ── Firestore offline persistence ──────────────────────────────────────
  // Caches data on disk so the second app launch reads from the local
  // cache INSTANTLY while Firestore syncs in the background.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ── Offline support (mobile) ───────────────────────────────────────────
  // Watch the connection, then start the upload outbox: files and signatures
  // captured with no signal are kept on the phone and uploaded automatically
  // when it comes back (also picks up anything left from a previous run).
  if (!kIsWeb) {
    await ConnectivityService.instance.start();
    unawaited(UploadOutbox.instance.start());
  }

  // App language (English / Afrikaans): the device's last choice, and the
  // date/month names for both languages.
  await LocaleProvider.instance.init();

  // Register the push background handler (must be done before runApp).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  print('⏱️  [Boot] runApp at: ${boot.elapsedMilliseconds} ms');

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: LocaleProvider.instance),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ChangeNotifierProvider(create: (_) => AuditProvider()),
      ChangeNotifierProvider(create: (_) => RouteProvider()),
      ChangeNotifierProvider(create: (_) => PayslipProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: const AgriComplianceApp(),
  ));
}


class AgriComplianceApp extends StatefulWidget {
  const AgriComplianceApp({Key? key}) : super(key: key);

  @override
  State<AgriComplianceApp> createState() => _AgriComplianceAppState();
}

class _AgriComplianceAppState extends State<AgriComplianceApp> {
  bool _precached = false;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = Provider.of<AuthProvider>(context, listen: false);
    _auth.addListener(_onAuthChanged);
  }

  String? _languageFor; // user id whose saved language was last applied

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// If the signed-in Firebase account changed underneath us (e.g. another tab
  /// signed in as someone else), drop everything cached for the old session and
  /// return to the login page.
  void _onAuthChanged() {
    // Follow the signed-in user's saved language (once per user).
    final uid = _auth.currentUser?.id;
    if (uid != _languageFor) {
      _languageFor = uid;
      LocaleProvider.instance.adoptUser(_auth.currentUser);
    }
    if (!_auth.takeSessionEnded()) return;
    Provider.of<DocumentProvider>(context, listen: false).clearContext();
    Provider.of<CategoryProvider>(context, listen: false).clearCompanyOverrides();
    Provider.of<NotificationProvider>(context, listen: false).stop();
    FirestoreService.invalidateReferenceData();
    appNavigatorKey.currentState
        ?.pushNamedAndRemoveUntil(RouteConstants.login, (_) => false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache assets the dashboard + splash need so they're decoded and
    // ready before the user ever sees them — no flash of empty hero.
    if (!_precached) {
      _precached = true;
      precacheImage(
          const AssetImage('assets/images/image1-4.webp'), context);
      // Precache the splash logo SVG so it renders on the first frame.
      final loader = SvgAssetLoader('assets/svg/logoIcon.svg');
      svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locale = Provider.of<LocaleProvider>(context).locale;

    // If the browser was opened directly on the video-ad stage
    // (http://localhost:PORT/#/video-ad), boot straight into it —
    // no auth wrapper, no login redirect. Marketing stage only.
    final bootRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final isVideoAd = bootRoute.startsWith(RouteConstants.videoAd);

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: LocaleProvider.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // The first screen comes from onGenerateInitialRoutes below. Don't also
      // set `home:` — Flutter asserts that only one is used, which crashes
      // debug builds on startup (release builds skip the check).
      //
      // On a page reload the browser URL (e.g. #/payslip-manager) used to be
      // built straight away, on top of the sign-in check, before the user was
      // loaded — so that screen showed no user (the old "Nathan Test"
      // placeholder) and never loaded its data. Now only the sign-in check is
      // built on boot; it returns the user to that screen once they're loaded.
      onGenerateInitialRoutes: (initialRoute) => [
        MaterialPageRoute(
          settings: const RouteSettings(name: '/'),
          builder: (_) => isVideoAd
              ? const VideoAnimationScreen()
              : AuthWrapper(requestedRoute: initialRoute),
        ),
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      // Offline / "uploading" status bar along the bottom of every screen.
      builder: (context, child) =>
          OfflineShell(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// NEW: AuthWrapper checks for existing Firebase session on app start
/// This prevents logging out on page refresh
class AuthWrapper extends StatefulWidget {
  /// The route in the browser URL when the app (re)loaded, if any.
  final String? requestedRoute;

  const AuthWrapper({Key? key, this.requestedRoute}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Defer to after the first frame so AuthProvider.notifyListeners()
    // doesn't fire during the current build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExistingSession());
  }

  Future<void> _checkExistingSession() async {
    final sw = Stopwatch()..start();
    print('⏱️  [Auth] session check START');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // This checks if user is already logged in (Firebase persists sessions)
      await authProvider.initializeUser();
      print('⏱️  [Auth] initializeUser: ${sw.elapsedMilliseconds} ms  '
          '(authenticated=${authProvider.isAuthenticated})');
    } catch (e) {
      print('Session check error: $e');
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
      print('⏱️  [Auth] session check TOTAL: ${sw.elapsedMilliseconds} ms');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Single brand splash for all 3 loading states — feels like ONE
    // continuous screen instead of three different spinner flashes.
    if (_isChecking) {
      return const _BrandSplash();
    }

    final authProvider = Provider.of<AuthProvider>(context);

    // Navigate exactly once. This widget rebuilds on every auth change, and
    // each rebuild used to queue another replacement — creating duplicate
    // dashboards that loaded their data twice.
    if (!_navigated) {
      _navigated = true;
      final target = authProvider.isAuthenticated
          ? (_restorableRoute(authProvider) ?? authProvider.homeRoute)
          : RouteConstants.login;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(target);
        // Signed in and home: open a notification the user tapped to launch
        // the app (held until now).
        if (authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => PushNotificationService.instance.markAppReady());
        }
      });
    }
    return const _BrandSplash();
  }
}

/// Screens without arguments that make sense to reopen after a page reload.
const Set<String> _farmScreens = {
  RouteConstants.dashboard,
  RouteConstants.auditTracker,
  RouteConstants.complianceReport,
  RouteConstants.auditIndex,
  RouteConstants.notifications,
  RouteConstants.payslipManager,
};
const Set<String> _farmableScreens = {
  RouteConstants.sprayRecords,
  RouteConstants.farmRegister,
  RouteConstants.farmMap,
};
const Set<String> _adminScreens = {
  RouteConstants.adminDashboard,
  RouteConstants.userManagement,
  RouteConstants.categoryManagement,
  RouteConstants.companyManagement,
  RouteConstants.overrid,
  RouteConstants.formConfigManagement,
  RouteConstants.dataFixUtility,
  RouteConstants.farmableConsole,
};

extension on _AuthWrapperState {
  /// The screen from the reloaded URL, if this user may reopen it now;
  /// otherwise null (→ their normal home screen).
  String? _restorableRoute(AuthProvider auth) {
    var r = widget.requestedRoute;
    if (r == null || r.isEmpty || r == '/') return null;
    final q = r.indexOf('?');
    if (q != -1) r = r.substring(0, q);

    if (auth.isAuditer) {
      return (r == RouteConstants.auditIndex ||
              (r == RouteConstants.myFarms && auth.canSwitchCompany))
          ? r
          : null;
    }
    if (r == RouteConstants.myFarms) return auth.canSwitchCompany ? r : null;
    if (_adminScreens.contains(r)) return auth.isAdmin ? r : null;

    final farmInView = auth.effectiveCompany != null &&
        (!auth.isAdmin || auth.isManagingCompany);
    if (!farmInView) return null;
    if (_farmScreens.contains(r)) return r;
    if (_farmableScreens.contains(r)) {
      return auth.effectiveCompany?.hasFarmable == true ? r : null;
    }
    return null; // detail screens need arguments the URL doesn't carry
  }
}

// ── Brand splash ─────────────────────────────────────────────────────────────
//
// A single clean splash used everywhere the app is "starting up" — so the
// user sees one continuous brand identity instead of multiple loading
// flashes. Green background, centered logo with a subtle pulse.

class _BrandSplash extends StatefulWidget {
  const _BrandSplash();

  @override
  State<_BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<_BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) {
            final scale = 0.96 + (_ctrl.value * 0.06);
            final opacity = 0.85 + (_ctrl.value * 0.15);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: SvgPicture.asset(
            'assets/svg/logoIcon.svg',
            width: 96,
            height: 96,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}