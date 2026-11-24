// ═══════════════════════════════════════════════════════════════════════════
// VIDEO AD ANIMATION — Crop Compliance
//
// A scripted, self-contained motion-design "stage" for screen recording a
// paid social ad (Instagram / WhatsApp stories).
//
//   • Canvas: 1080 × 1920 design pixels (9:16), letterboxed into any window.
//   • 250 px of intentionally blank space at the very top AND bottom.
//   • Showcases the REAL desktop app: real logo (assets/svg/logoIcon.svg),
//     real sidebar banner (assets/images/menuImage.webp), real dashboard hero
//     (assets/images/image1-4.webp), real theme colours (#43A047 primary),
//     and faithful replicas of the actual screens.
//   • 7 scenes ≈ 48 s: Intro → Dashboard → Audit Tracker →
//     Compliance Report → Payslip Manager → Notifications → Outro.
//
// HOW TO RUN + RECORD
//   flutter run -d chrome --release
//   open  http://localhost:<port>/#/video-ad   (reload on that URL)
//   Click once to start. Record at 1080×1920.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ── REAL app palette (theme_constants.dart) ──────────────────────────────────
const _kPrimary = Color(0xFF43A047); // ThemeConstants.primaryColor
const _kGaugeGreen = Color(0xFF4CAF50); // Colors.green — real gauge colour
const _kSaveGreen = Color(0xFF388E3C); // Colors.green.shade700 — Save button
const _kApproved = Color(0xFF81C784); // ThemeConstants.approvedColor
const _kPending = Color(0xFFFFD54F); // ThemeConstants.pendingColor
const _kRejected = Color(0xFFE57373); // ThemeConstants.rejectedColor
const _kInk = Color(0xFF1E1E1E); // primaryTextColor
const _kGrey = Color(0xFF616161); // secondaryTextColor
const _kGrey400 = Color(0xFFBDBDBD);
const _kGrey300 = Color(0xFFE0E0E0);
const _kGrey100 = Color(0xFFF5F5F5);
const _kGrey50 = Color(0xFFFAFAFA);

// Ad-stage dressing (outside the app frame only)
const _kBgTop = Color(0xFFF7FBF7);
const _kBgBot = Color(0xFFEAF3EB);

const double _stageW = 1080;
const double _stageH = 1920;
const double _safe = 250; // blank top & bottom

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN + SEQUENCER
// ═══════════════════════════════════════════════════════════════════════════

class VideoAnimationScreen extends StatefulWidget {
  const VideoAnimationScreen({Key? key}) : super(key: key);

  @override
  State<VideoAnimationScreen> createState() => _VideoAnimationScreenState();
}

class _VideoAnimationScreenState extends State<VideoAnimationScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  bool _finished = false;
  int _index = 0;

  late final AnimationController _bg =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))
        ..repeat(reverse: true);

  late final List<_SceneSpec> _scenes = [
    _SceneSpec(const Duration(milliseconds: 4600), (c, t) => _IntroScene(t: t)),
    _SceneSpec(const Duration(milliseconds: 11000), (c, t) => _DashboardScene(t: t)),
    _SceneSpec(const Duration(milliseconds: 7600), (c, t) => _TrackerScene(t: t)),
    _SceneSpec(const Duration(milliseconds: 7200), (c, t) => _ReportScene(t: t)),
    _SceneSpec(const Duration(milliseconds: 9400), (c, t) => _PayslipScene(t: t)),
    _SceneSpec(const Duration(milliseconds: 6400), (c, t) => _NotifyScene(t: t)),
    _SceneSpec(const Duration(milliseconds: 6800), (c, t) => _OutroScene(t: t)),
  ];

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  void _tap() {
    if (!_started) {
      setState(() => _started = true);
    } else if (_finished) {
      setState(() {
        _finished = false;
        _index = 0;
      });
    }
  }

  void _advance() {
    if (!mounted) return;
    if (_index < _scenes.length - 1) {
      setState(() => _index++);
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D120D),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _stageW,
              height: _stageH,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_kBgTop, _kBgBot],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(child: _Ambience(t: _bg)),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: _safe),
                      child: _started
                          ? AnimatedSwitcher(
                              duration: const Duration(milliseconds: 620),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, .05),
                                    end: Offset.zero,
                                  ).animate(a),
                                  child: child,
                                ),
                              ),
                              child: _finished
                                  ? const KeyedSubtree(
                                      key: ValueKey('end'),
                                      child: _OutroStatic(),
                                    )
                                  : _ScenePlayer(
                                      key: ValueKey('scene$_index'),
                                      duration: _scenes[_index].duration,
                                      builder: _scenes[_index].builder,
                                      onDone: _advance,
                                    ),
                            )
                          : _StartOverlay(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneSpec {
  const _SceneSpec(this.duration, this.builder);
  final Duration duration;
  final Widget Function(BuildContext, Animation<double>) builder;
}

class _ScenePlayer extends StatefulWidget {
  const _ScenePlayer({
    Key? key,
    required this.duration,
    required this.builder,
    required this.onDone,
  }) : super(key: key);
  final Duration duration;
  final Widget Function(BuildContext, Animation<double>) builder;
  final VoidCallback onDone;

  @override
  State<_ScenePlayer> createState() => _ScenePlayerState();
}

class _ScenePlayerState extends State<_ScenePlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _c);
}

// ═══════════════════════════════════════════════════════════════════════════
// CORE ANIMATION HELPERS
// ═══════════════════════════════════════════════════════════════════════════

double _iv(double v, double s, double e, [Curve c = Curves.easeOutCubic]) {
  if (e <= s) return v >= e ? 1 : 0;
  return c.transform(((v - s) / (e - s)).clamp(0.0, 1.0));
}

double _lerp(double a, double b, double u) => a + (b - a) * u;

class _In extends StatelessWidget {
  const _In({
    required this.t,
    required this.start,
    this.end,
    this.from = const Offset(0, 44),
    this.scaleFrom = 1.0,
    this.curve = Curves.easeOutCubic,
    required this.child,
  });
  final Animation<double> t;
  final double start;
  final double? end;
  final Offset from;
  final double scaleFrom;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Snappy default entrance; hero moments pass an explicit longer `end`.
    final e = end ?? (start + .10);
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (_, c) {
        final u = _iv(t.value, start, e, curve);
        return Opacity(
          opacity: u,
          child: Transform.translate(
            offset: Offset(from.dx * (1 - u), from.dy * (1 - u)),
            child: Transform.scale(scale: _lerp(scaleFrom, 1, u), child: c),
          ),
        );
      },
    );
  }
}

/// Camera keyframe: zoom level + the frame-local point (in the 980×660
/// design space) that should sit at the centre of the viewport.
class _FocusKey {
  const _FocusKey(this.t, this.scale, this.focus);
  final double t;
  final double scale;
  final Offset focus;
}

/// Camera rig with EDGE CLAMPING:
///  • wide shots are centred and never cropped,
///  • zoomed shots always fill the viewport completely — the frame's edges
///    can never drift into view (no "cut" artefacts).
/// The child (frame + cursor) lives in a fixed 980×660 space, so all
/// cursor coordinates remain exact at any zoom.
class _CameraStage extends StatelessWidget {
  const _CameraStage({
    required this.t,
    required this.keys,
    required this.child,
  });
  final Animation<double> t;
  final List<_FocusKey> keys;
  final Widget child;

  static const double _w = 980;
  static const double _h = 660;

  (double, Offset) _at(double v) {
    if (v <= keys.first.t) return (keys.first.scale, keys.first.focus);
    for (var i = 0; i < keys.length - 1; i++) {
      final a = keys[i], b = keys[i + 1];
      if (v <= b.t) {
        var u = (v - a.t) / (b.t - a.t);
        u = Curves.easeInOutCubic.transform(u.clamp(0.0, 1.0));
        return (
          _lerp(a.scale, b.scale, u),
          Offset.lerp(a.focus, b.focus, u)!,
        );
      }
    }
    return (keys.last.scale, keys.last.focus);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return AnimatedBuilder(
          animation: t,
          builder: (_, __) {
            final (s, f) = _at(t.value);
            final w = _w * s, h = _h * s;
            double left = c.maxWidth / 2 - f.dx * s;
            double top = c.maxHeight / 2 - f.dy * s;
            // Clamp: if the scaled frame is larger than the viewport, pin
            // its edges outside; if smaller, centre it.
            left = w >= c.maxWidth
                ? left.clamp(c.maxWidth - w, 0.0)
                : (c.maxWidth - w) / 2;
            top = h >= c.maxHeight
                ? top.clamp(c.maxHeight - h, 0.0)
                : (c.maxHeight - h) / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: w,
                  height: h,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(width: _w, height: _h, child: child),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PtKey {
  const _PtKey(this.t, this.p);
  final double t;
  final Offset p;
}

Offset _ptAt(List<_PtKey> keys, double v) {
  if (v <= keys.first.t) return keys.first.p;
  for (var i = 0; i < keys.length - 1; i++) {
    final a = keys[i], b = keys[i + 1];
    if (v <= b.t) {
      var u = (v - a.t) / (b.t - a.t);
      u = Curves.easeInOutCubic.transform(u.clamp(0.0, 1.0));
      return Offset.lerp(a.p, b.p, u)!;
    }
  }
  return keys.last.p;
}

class _Pointer extends StatelessWidget {
  const _Pointer({
    required this.t,
    required this.path,
    this.clicks = const [],
    this.appear = 0,
  });
  final Animation<double> t;
  final List<_PtKey> path;
  final List<double> clicks;
  final double appear;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (_, __) {
        final v = t.value;
        final p = _ptAt(path, v);
        final show = _iv(v, appear, appear + .06);
        double press = 0;
        for (final c in clicks) {
          final d = (v - c).abs();
          if (d < .045) press = math.max(press, 1 - d / .045);
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final c in clicks)
              Positioned(
                left: p.dx - 34,
                top: p.dy - 34,
                child: _ripple(v, c),
              ),
            Positioned(
              left: p.dx,
              top: p.dy,
              child: Opacity(
                opacity: show,
                child: Transform.scale(
                  scale: 1 - .18 * press,
                  alignment: Alignment.topLeft,
                  child: const CustomPaint(
                    size: Size(30, 34),
                    painter: _CursorPainter(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ripple(double v, double at) {
    final u = _iv(v, at, at + .12, Curves.easeOut);
    if (u == 0 || u == 1) return const SizedBox.shrink();
    return IgnorePointer(
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _kPrimary.withOpacity(.55 * (1 - u)),
            width: 3,
          ),
        ),
        transform: Matrix4.identity()
          ..translate(34.0, 34.0)
          ..scale(.3 + .9 * u)
          ..translate(-34.0, -34.0),
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  const _CursorPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 24)
      ..lineTo(6.4, 18.6)
      ..lineTo(11.2, 29)
      ..lineTo(15.4, 27)
      ..lineTo(10.6, 16.8)
      ..lineTo(18.6, 16)
      ..close();
    canvas.drawShadow(path, Colors.black45, 3, true);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = _kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CountUp extends StatelessWidget {
  const _CountUp({
    required this.t,
    required this.start,
    required this.end,
    required this.from,
    required this.to,
    required this.style,
    this.formatter,
  });
  final Animation<double> t;
  final double start, end, from, to;
  final TextStyle style;
  final String Function(double)? formatter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (_, __) {
        final u = _iv(t.value, start, end, Curves.easeOutCubic);
        final val = _lerp(from, to, u);
        final txt = formatter?.call(val) ?? val.round().toString();
        return Text(txt, style: style);
      },
    );
  }
}

String _fmtR(double v) {
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final digits = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buf.write(digits[i]);
    final left = digits.length - 1 - i;
    if (left > 0 && left % 3 == 0) buf.write(' ');
  }
  return 'R ${buf.toString()}.${parts[1]}';
}

// ═══════════════════════════════════════════════════════════════════════════
// STAGE DRESSING
// ═══════════════════════════════════════════════════════════════════════════

class _Ambience extends StatelessWidget {
  const _Ambience({required this.t});
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      builder: (_, __) {
        final v = Curves.easeInOut.transform(t.value);
        return Stack(
          children: [
            Positioned(
              left: -260 + 60 * v,
              top: 260 + 120 * v,
              child: _glow(680, _kApproved.withOpacity(.16)),
            ),
            Positioned(
              right: -300 - 40 * v,
              bottom: 240 + 100 * (1 - v),
              child: _glow(760, _kPrimary.withOpacity(.10)),
            ),
          ],
        );
      },
    );
  }

  Widget _glow(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c, c.withOpacity(0)]),
        ),
      );
}

/// The REAL app logo (assets/svg/logoIcon.svg) in a soft white disc.
class _RealLogo extends StatelessWidget {
  const _RealLogo({this.size = 150});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .17),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(.30),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SvgPicture.asset('assets/svg/logoIcon.svg', fit: BoxFit.contain),
    );
  }
}

class _StartOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _RealLogo(size: 150),
          const SizedBox(height: 44),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 24),
            decoration: BoxDecoration(
              color: _kInk,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42),
                SizedBox(width: 12),
                Text(
                  'Click to play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start your screen recording first',
            style: TextStyle(color: _kGrey, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

// ── Caption block ────────────────────────────────────────────────────────────

const _headStyle = TextStyle(
  fontSize: 86,
  fontWeight: FontWeight.w900,
  color: _kInk,
  height: 1.0,
  letterSpacing: -2.2,
);
const _subStyle = TextStyle(
  fontSize: 31,
  fontWeight: FontWeight.w500,
  color: _kGrey,
  height: 1.4,
);

class _Caption extends StatelessWidget {
  const _Caption({
    required this.t,
    required this.eyebrow,
    required this.head,
    this.sub,
  });
  final Animation<double> t;
  final String eyebrow;
  final String head;
  final String? sub;
  static const double start = .02;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(76, 34, 76, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _In(
            t: t,
            start: start,
            from: const Offset(-30, 0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  eyebrow,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 5.5,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _In(
            t: t,
            start: start + .04,
            from: const Offset(0, 46),
            child: Text(head, style: _headStyle),
          ),
          if (sub != null) ...[
            const SizedBox(height: 22),
            _In(
              t: t,
              start: start + .11,
              from: const Offset(0, 30),
              child: Text(sub!, style: _subStyle),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REAL APP SHELL — browser chrome + green AppBar + real sidebar
// ═══════════════════════════════════════════════════════════════════════════

class _DesktopFrame extends StatelessWidget {
  const _DesktopFrame({
    required this.slug,
    required this.title,
    required this.selected,
    required this.child,
  });
  final String slug; // address-bar path
  final String title; // AppBar title
  final int selected; // sidebar highlight
  final Widget child;
  static const int bellCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 980,
      height: 660,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(.20),
            blurRadius: 70,
            offset: const Offset(0, 34),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Browser chrome
            Container(
              height: 52,
              color: const Color(0xFFF1F3F1),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _dot(const Color(0xFFF66358)),
                  const SizedBox(width: 8),
                  _dot(const Color(0xFFF5BD4F)),
                  const SizedBox(width: 8),
                  _dot(const Color(0xFF53C22B)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kGrey300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, size: 13, color: _kPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'crop-compliance.com/$slug',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _kGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // REAL green AppBar (menu icon, title, bell with badge)
            Container(
              height: 46,
              color: _kPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.menu_open, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                      if (bellCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            constraints: const BoxConstraints(
                                minWidth: 15, minHeight: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(9),
                              border:
                                  Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              '$bellCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Sidebar + page content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RealSidebar(selected: selected),
                  Container(width: 1, color: _kGrey300),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

/// Faithful replica of the real sidebar in app_scaffold_wrapper.dart:
/// banner image (menuImage.webp) → user profile → menu ListTiles.
class _RealSidebar extends StatelessWidget {
  const _RealSidebar({required this.selected});
  final int selected;

  static const _items = [
    (Icons.dashboard, 'Dashboard'),
    (Icons.track_changes, 'Audit Tracker'),
    (Icons.assessment, 'Compliance Report'),
    (Icons.folder, 'Audit Index'),
    (Icons.payments, 'Payslip Manager'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real banner image
          Image.asset(
            'assets/images/menuImage.webp',
            width: 196,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 196,
              height: 84,
              color: _kPrimary.withOpacity(.1),
            ),
          ),
          // User profile row (like _buildUserProfile)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _kPrimary.withOpacity(.15),
                  child: const Text(
                    'N',
                    style: TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nathan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                    ),
                    Text(
                      'Admin',
                      style: TextStyle(fontSize: 11, color: _kGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kGrey300),
          const SizedBox(height: 6),
          for (var i = 0; i < _items.length; i++) _tile(i),
        ],
      ),
    );
  }

  // Mirrors _buildMenuItem: icon 20, grey600 → primaryColor when selected.
  Widget _tile(int i) {
    final sel = i == selected;
    return Container(
      color: sel ? _kPrimary.withOpacity(.08) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            _items[i].$1,
            size: 18,
            color: sel ? _kPrimary : const Color(0xFF757575),
          ),
          const SizedBox(width: 12),
          Text(
            _items[i].$2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? _kPrimary : _kGrey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge with the REAL status colours.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label, this.kind);
  final String label;
  final int kind; // 0 approved, 1 pending, 2 rejected

  @override
  Widget build(BuildContext context) {
    final base = switch (kind) {
      0 => _kApproved,
      1 => _kPending,
      _ => _kRejected,
    };
    final text = switch (kind) {
      0 => const Color(0xFF2E7D32),
      1 => const Color(0xFF9A6E00),
      _ => const Color(0xFFC62828),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}

/// The REAL gauge painter (dashboard_compliance_card.dart) — round caps.
class _RealGaugePainter extends CustomPainter {
  const _RealGaugePainter({required this.percentage});
  final double percentage;
  // Real dashboard gauge parameters, scaled to the mock frame.
  static const int lineCount = 24;
  static const double dashLength = 15;
  static const double dashWidth = 4;
  static const double radius = 42;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);
    final progressLines = (percentage * lineCount).round();
    for (var i = 0; i < lineCount; i++) {
      final angle = math.pi - (i / (lineCount - 1)) * math.pi;
      final isProgress = i < progressLines;
      final paint = Paint()
        ..color = isProgress ? _kGaugeGreen : Colors.grey.withOpacity(0.5)
        ..strokeWidth = dashWidth
        ..strokeCap = StrokeCap.round;
      final inner =
          center + Offset(radius * math.cos(angle), -radius * math.sin(angle));
      final outer = center +
          Offset((radius + dashLength) * math.cos(angle),
              -(radius + dashLength) * math.sin(angle));
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealGaugePainter old) =>
      old.percentage != percentage;
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE 1 — INTRO
// ═══════════════════════════════════════════════════════════════════════════

class _IntroScene extends StatelessWidget {
  const _IntroScene({required this.t});
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _In(
            t: t,
            start: .03,
            end: .34,
            scaleFrom: .3,
            from: Offset.zero,
            curve: Curves.easeOutBack,
            child: const _RealLogo(size: 190),
          ),
          const SizedBox(height: 52),
          _In(
            t: t,
            start: .22,
            from: const Offset(0, 40),
            child: const Text(
              'Crop Compliance',
              style: TextStyle(
                fontSize: 88,
                fontWeight: FontWeight.w900,
                letterSpacing: -2.5,
                color: _kInk,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 26),
          _In(
            t: t,
            start: .34,
            from: const Offset(0, 28),
            child: const Text(
              'Run your farm. We\'ll run the paperwork.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: _kGrey,
              ),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pkg(.48, Icons.people, 'SIZA / WIETA'),
              const SizedBox(width: 22),
              _pkg(.56, Icons.eco, 'GlobalG.A.P.'),
              const SizedBox(width: 22),
              _pkg(.64, Icons.wine_bar, 'IPW'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pkg(double start, IconData icon, String label) {
    return _In(
      t: t,
      start: start,
      from: const Offset(0, 34),
      scaleFrom: .85,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _kPrimary.withOpacity(.30), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kPrimary, size: 26),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE 2 — DASHBOARD (faithful to dashboard_screen.dart)
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardScene extends StatelessWidget {
  const _DashboardScene({required this.t});
  final Animation<double> t;

  // Choreography timing (fractions of the 11 s scene)
  static const double _clickAt = .60; // cursor clicks the rejected row
  static const double _overlayAt = .64; // rejection comment pops out

  // Camera: full wide view while everything loads (nothing cropped),
  // then a single push onto the document being clicked. No gauge zoom.
  static const _cam = [
    _FocusKey(0, 1.0, Offset(490, 330)),
    _FocusKey(.44, 1.0, Offset(490, 330)), // whole dashboard, fully visible
    _FocusKey(.52, 1.9, Offset(580, 547)), // push onto the rejected row
    _FocusKey(.68, 1.9, Offset(580, 547)),
    _FocusKey(.76, 1.05, Offset(490, 330)), // pull back for the pop-out
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(
          t: t,
          eyebrow: 'DASHBOARD',
          head: 'Your whole farm,\none glance.',
          sub: 'Live compliance score, documents and payroll,\nthe moment you log in.',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: t,
              builder: (_, __) {
                final ov = _iv(t.value, _overlayAt, _overlayAt + .10);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _In(
                      t: t,
                      start: .06,
                      end: .20,
                      from: const Offset(0, 110),
                      scaleFrom: .96,
                      child: _CameraStage(
                        t: t,
                        keys: _cam,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _DesktopFrame(
                              slug: 'dashboard',
                              title: 'Dashboard',
                              selected: 0,
                              child: _body(),
                            ),
                            Positioned.fill(
                              child: _Pointer(
                                t: t,
                                appear: .48,
                                path: const [
                                  _PtKey(.48, Offset(700, 430)),
                                  _PtKey(.57, Offset(580, 547)),
                                  _PtKey(1, Offset(580, 547)),
                                ],
                                clicks: const [_clickAt],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Dim layer behind the pop-out
                    IgnorePointer(
                      child: Container(
                        color: Colors.black.withOpacity(.32 * ov),
                      ),
                    ),
                    // The rejection comment — BIG, standalone, unscaled
                    Center(
                      child: _In(
                        t: t,
                        start: _overlayAt,
                        end: _overlayAt + .13,
                        from: const Offset(0, 90),
                        scaleFrom: .82,
                        curve: Curves.easeOutBack,
                        child: _rejectionCard(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// The standalone pop-out: WHY the document was rejected.
  Widget _rejectionCard() {
    return Container(
      width: 680,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: Color(0xFFE53935), size: 30),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Potable Water',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '9. Water Management  ·  uploaded 3 days ago',
                      style: TextStyle(fontSize: 15, color: _kGrey),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.25,
                child: const _StatusBadge('Rejected', 2),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'AUDITOR COMMENT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              color: _kGrey400,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: const Text(
              '“E. coli is detected in the water analysis.\nHas to be retested at a SANAS accredited lab.”',
              style: TextStyle(
                fontSize: 21,
                color: _kInk,
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file, color: Colors.white, size: 19),
                    SizedBox(width: 9),
                    Text(
                      'Resubmit document',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'You\'ll be notified when it\'s approved.',
                style: TextStyle(fontSize: 14.5, color: _kGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Real layout: left col (flex 3) Employees + Comments; right col (flex 7)
  // compliance hero card + documents table.
  Widget _body() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _In(
                  t: t,
                  start: .12,
                  from: const Offset(-26, 0),
                  child: _employeesCard(),
                ),
                const SizedBox(height: 12),
                _In(
                  t: t,
                  start: .15,
                  from: const Offset(-26, 0),
                  child: _commentsCard(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _In(
                  t: t,
                  start: .12,
                  from: const Offset(0, 30),
                  child: _heroCard(),
                ),
                const SizedBox(height: 12),
                _In(
                  t: t,
                  start: .14,
                  from: const Offset(0, 30),
                  child: _documentsTable(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The real compliance hero: image1-4.webp + gauge + glass KPI tiles.
  Widget _heroCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/image1-4.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: _kPrimary.withOpacity(.2)),
            ),
            Container(color: Colors.black.withOpacity(.10)),
            const Positioned(
              top: 10,
              left: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, Nathan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome back.',
                    style: TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            // Gauge — deliberately unhurried count-up (the hero moment)
            Positioned(
              top: 46,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 100,
                child: AnimatedBuilder(
                  animation: t,
                  builder: (_, __) => CustomPaint(
                    painter: _RealGaugePainter(
                      percentage: _iv(t.value, .20, .42) * .87,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _CountUp(
                          t: t,
                          start: .20,
                          end: .42,
                          from: 0,
                          to: 87,
                          style: const TextStyle(
                            color: _kGaugeGreen,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                          formatter: (v) => '${v.round()}%',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Glass KPI tiles (real: 4 across the bottom)
            Positioned(
              bottom: 5,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  _kpiGlass(.20, Icons.trending_up, 'Completion Rate', '46/125', '87%'),
                  const SizedBox(width: 6),
                  _kpiGlass(.22, Icons.check_circle_outline, 'Approval Rate', '46/52', '88.5%'),
                  const SizedBox(width: 6),
                  _kpiGlass(.24, Icons.hourglass_empty, 'Pending Review', '4', 'Action Needed'),
                  const SizedBox(width: 6),
                  _kpiGlass(.26, Icons.cancel_outlined, 'Rejected Item', '1', 'Needs Attention'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiGlass(
      double start, IconData icon, String title, String value, String sub) {
    return Expanded(
      child: _In(
        t: t,
        start: start,
        from: const Offset(0, 22),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 11),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.white, fontSize: 7.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentsTable() {
    // 9 approved + 1 rejected (index 6) — the rejected one is the story.
    const rows = [
      ('BEE Certification Documents', 'Business', 0),
      ('Employment Contracts', 'Labour', 0),
      ('Spray Records (Block 4B)', 'Crop protection', 0),
      ('List of Good Practices', 'Ethical', 0),
      ('Risk Assessments, All Sites', 'Health & safety', 0),
      ('First-Aid Training Records', 'Health & safety', 0),
      ('Analysis Potable Water', 'Water Management', 2),
      ('Chemical Storage Certificates', 'Crop protection', 0),
      ('Waste Disposal Records', 'Environment', 0),
      ('PPE Issue Register', 'Health & safety', 0),
    ];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed heights: title 26 + header 20 + rows 21 each, so the
          // rejected row's click target is at an exact, known position.
          const SizedBox(
            height: 26,
            child: Padding(
              padding: EdgeInsets.only(left: 12, top: 7),
              child: Text(
                'Documents',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kInk,
                ),
              ),
            ),
          ),
          Container(
            height: 20,
            color: _kGrey100,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('DOCUMENT', style: _th)),
                Expanded(flex: 3, child: Text('CATEGORY', style: _th)),
                Expanded(flex: 2, child: Text('STATUS', style: _th)),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            _docRow(
              .18 + i * .013, // very fast cascade, done before the zoom
              rows[i].$1,
              rows[i].$2,
              rows[i].$3,
              highlight: rows[i].$3 == 2,
            ),
        ],
      ),
    );
  }

  static const _th = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.bold,
    color: _kGrey,
    letterSpacing: .4,
  );

  Widget _docRow(double start, String name, String cat, int status,
      {bool highlight = false}) {
    final label = switch (status) { 0 => 'Approved', 1 => 'Pending', _ => 'Rejected' };
    Widget row(double emphasis) => Container(
          height: 21, // fixed → click coordinates are exact
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.lerp(
                Colors.transparent, const Color(0xFFFFEBEE), emphasis),
            border: Border(
              bottom: const BorderSide(color: _kGrey300, width: .6),
              left: BorderSide(
                color: const Color(0xFFE53935).withOpacity(emphasis),
                width: 3 * emphasis,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        size: 12, color: _kGrey),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _kInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  cat,
                  style: const TextStyle(fontSize: 10, color: _kGrey),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (switch (status) {
                        0 => _kApproved,
                        1 => _kPending,
                        _ => _kRejected,
                      })
                          .withOpacity(.22),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: switch (status) {
                          0 => const Color(0xFF2E7D32),
                          1 => const Color(0xFF9A6E00),
                          _ => const Color(0xFFC62828),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

    return _In(
      t: t,
      start: start,
      from: const Offset(26, 0),
      child: highlight
          ? AnimatedBuilder(
              animation: t,
              builder: (_, __) => row(_iv(t.value, .50, .56)),
            )
          : row(0),
    );
  }

  Widget _employeesCard() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employees',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 10),
            _emp('Alice Mostert', 'Farm Worker'),
            _emp('Brian Nkosi', 'Tractor Driver'),
            _emp('Carol van Wyk', 'Packhouse'),
          ],
        ),
      ),
    );
  }

  Widget _emp(String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: _kPrimary.withOpacity(.15),
            child: Text(
              name[0],
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 11, color: _kGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentsCard() {
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document Comments',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 10),
            _comment('Water analysis must be redone.\nE. coli detected.'),
            const SizedBox(height: 8),
            _comment('Please add expiry date to the\nBEE certificate.'),
          ],
        ),
      ),
    );
  }

  Widget _comment(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kGrey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGrey300, width: .6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, color: _kGrey, height: 1.3),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGrey300, width: .7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE 3 — AUDIT TRACKER (faithful to audit_tracker_screen.dart)
// ═══════════════════════════════════════════════════════════════════════════

class _TrackerScene extends StatelessWidget {
  const _TrackerScene({required this.t});
  final Animation<double> t;

  static const _cam = [
    _FocusKey(0, 1.0, Offset(490, 330)),
    _FocusKey(.38, 1.0, Offset(490, 330)), // full page loads, uncropped
    _FocusKey(.48, 1.7, Offset(490, 340)), // push onto the document cards
    _FocusKey(.92, 1.7, Offset(490, 340)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(
          t: t,
          eyebrow: 'AUDIT TRACKER',
          head: 'Audit-ready,\nevery day.',
          sub: 'Every required document, tracked by category.\nSee exactly what\'s missing before the auditor does.',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ClipRect(
            child: _In(
              t: t,
              start: .06,
              end: .20,
              from: const Offset(0, 110),
              scaleFrom: .96,
              child: _CameraStage(
                t: t,
                keys: _cam,
                child: _DesktopFrame(
                  slug: 'audit-tracker',
                  title: 'Audit Tracker',
                  selected: 1,
                  child: _body(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real KPI cards: blue / green / orange / red
          Row(
            children: [
              _kpi(.18, 'Completion Rate', '17/298', '5.7%',
                  const Color(0xFF2196F3), Icons.insert_chart),
              const SizedBox(width: 10),
              _kpi(.21, 'Approval Rate', '5/17', '29.4%',
                  const Color(0xFF4CAF50), Icons.check_circle),
              const SizedBox(width: 10),
              _kpi(.24, 'Pending Review', '3', 'Action needed',
                  const Color(0xFFFF9800), Icons.hourglass_empty),
              const SizedBox(width: 10),
              _kpi(.27, 'Rejected Items', '3', 'Needs attention',
                  const Color(0xFFF44336), Icons.error_outline),
            ],
          ),
          const SizedBox(height: 14),
          // Real package toggle buttons
          Row(
            children: [
              _toggle(.32, Icons.people, 'SIZA/WIETA', true),
              const SizedBox(width: 10),
              _toggle(.35, Icons.eco, 'GlobalG.A.P.', false),
              const SizedBox(width: 10),
              _toggle(.38, Icons.wine_bar, 'IPW', false),
            ],
          ),
          const SizedBox(height: 12),
          _docCard(.48, 'Document control procedure',
              '1. Internal Documentation · expires 12 Mar 2027', 0),
          _docCard(.55, 'Completed self-assessment / internal audit',
              '1. Internal Documentation · uploaded 2 days ago', 1,
              flipAt: .74),
          _docCard(.62, 'Analysis Potable Water',
              '9. Water Management · SANAS accredited lab', 2),
        ],
      ),
    );
  }

  Widget _kpi(double start, String title, String value, String sub,
      Color color, IconData icon) {
    return Expanded(
      child: _In(
        t: t,
        start: start,
        from: const Offset(0, 24),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 10.5,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kInk,
                      ),
                    ),
                    Text(
                      sub,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9.5, color: _kGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(double start, IconData icon, String label, bool sel) {
    return _In(
      t: t,
      start: start,
      from: const Offset(0, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? _kPrimary : _kGrey300),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: sel ? Colors.white : _kGrey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : _kGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docCard(double start, String name, String sub, int status,
      {double? flipAt}) {
    final label = switch (status) { 0 => 'Approved', 1 => 'Pending', _ => 'Rejected' };
    return _In(
      t: t,
      start: start,
      from: const Offset(40, 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGrey300, width: .7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.description_outlined,
                  size: 19, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 11.5, color: _kGrey),
                  ),
                ],
              ),
            ),
            if (flipAt == null)
              _StatusBadge(label, status)
            else
              AnimatedBuilder(
                animation: t,
                builder: (_, __) {
                  final flip = _iv(t.value, flipAt, flipAt + .08);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 1 - flip,
                        child: const _StatusBadge('Pending', 1),
                      ),
                      Opacity(
                        opacity: flip,
                        child: Transform.scale(
                          scale: .7 + .3 * flip,
                          child: const _StatusBadge('Approved', 0),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE 4 — COMPLIANCE REPORT
// ═══════════════════════════════════════════════════════════════════════════

class _ReportScene extends StatelessWidget {
  const _ReportScene({required this.t});
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(
          t: t,
          eyebrow: 'COMPLIANCE REPORT',
          head: 'One click.\nAudit done.',
          sub: 'A clean, professional report, ready to hand\nto any auditor, any day of the year.',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ClipRect(
            child: _In(
              t: t,
              start: .06,
              end: .20,
              from: const Offset(0, 110),
              scaleFrom: .96,
              child: _CameraStage(
                t: t,
                keys: _cam,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _DesktopFrame(
                      slug: 'compliance-report',
                      title: 'Compliance Report',
                      selected: 2,
                      child: _body(),
                    ),
                    Positioned(
                      right: 26,
                      top: 70,
                      child: _In(
                        t: t,
                        start: .62,
                        end: .80,
                        from: const Offset(0, 160),
                        scaleFrom: .92,
                        child: _pdfSheet(),
                      ),
                    ),
                    Positioned.fill(
                      child: _Pointer(
                        t: t,
                        appear: .28,
                        path: const [
                          _PtKey(.28, Offset(560, 500)),
                          _PtKey(.46, Offset(860, 620)),
                          _PtKey(.58, Offset(860, 620)),
                          _PtKey(.72, Offset(700, 420)),
                        ],
                        clicks: const [.56],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const _cam = [
    _FocusKey(0, 1.0, Offset(490, 330)),
    _FocusKey(.34, 1.0, Offset(490, 330)), // full page loads, uncropped
    _FocusKey(.44, 1.85, Offset(860, 600)), // the Download button click
    _FocusKey(.62, 1.85, Offset(860, 600)),
    _FocusKey(.72, 1.45, Offset(800, 280)), // the PDF sliding up
  ];

  Widget _body() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _In(
            t: t,
            start: .16,
            from: const Offset(0, 20),
            child: const Text(
              'Compliance Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kInk,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _In(
            t: t,
            start: .18,
            from: const Offset(0, 16),
            child: const Text(
              'SIZA/WIETA · GlobalG.A.P. · IPW  ·  Generated 25 Jun 2026',
              style: TextStyle(fontSize: 12.5, color: _kGrey),
            ),
          ),
          const SizedBox(height: 12),
          _In(
            t: t,
            start: .21,
            from: const Offset(0, 18),
            child: const Row(
              children: [
                _StatusBadge('46 Approved', 0),
                SizedBox(width: 8),
                _StatusBadge('4 Pending', 1),
                SizedBox(width: 8),
                _StatusBadge('2 Rejected', 2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            color: _kGrey100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('DOCUMENT', style: _DashboardScene._th)),
                Expanded(flex: 3, child: Text('CATEGORY', style: _DashboardScene._th)),
                Expanded(flex: 2, child: Text('STATUS', style: _DashboardScene._th)),
              ],
            ),
          ),
          _row(.25, 'Document control procedure', 'Internal docs', 0),
          _row(.29, 'Risk assessments, all sites', 'Health & safety', 0),
          _row(.33, 'Chemical storage certificates', 'Crop protection', 0),
          _row(.37, 'First-aid training records', 'Health & safety', 1),
          const Spacer(),
          // Real primary button style (radius 8, primary green)
          Align(
            alignment: Alignment.centerRight,
            child: _In(
              t: t,
              start: .42,
              from: const Offset(0, 20),
              child: AnimatedBuilder(
                animation: t,
                builder: (_, __) {
                  final press = 1 -
                      .06 * (1 - ((t.value - .56).abs() / .05).clamp(0.0, 1.0));
                  return Transform.scale(
                    scale: press,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Download Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(double start, String name, String cat, int status) {
    final label = switch (status) { 0 => 'Approved', 1 => 'Pending', _ => 'Rejected' };
    return _In(
      t: t,
      start: start,
      from: const Offset(36, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kGrey300, width: .6)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  const Icon(Icons.description_outlined,
                      size: 15, color: _kGrey),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                cat,
                style: const TextStyle(fontSize: 12, color: _kGrey),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(label, status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfSheet() {
    return Container(
      width: 290,
      height: 390,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.22),
            blurRadius: 46,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: SvgPicture.asset(
                  'assets/svg/logoIcon.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: _kPrimary, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'COMPLIANCE\nREPORT',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.05,
              color: _kInk,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Generated 25 June 2026',
            style: TextStyle(fontSize: 12.5, color: _kGrey400),
          ),
          const SizedBox(height: 20),
          for (final w in [1.0, .85, .92, .7, .88, .6])
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              height: 9,
              width: 240 * w,
              decoration: BoxDecoration(
                color: _kGrey300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '87% compliant · audit-ready',
              style: TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE 5 — PAYSLIP MANAGER (faithful to payslip_manager_screen.dart)
// ═══════════════════════════════════════════════════════════════════════════

class _PayslipScene extends StatelessWidget {
  const _PayslipScene({required this.t});
  final Animation<double> t;

  static const _cam = [
    _FocusKey(0, 1.0, Offset(490, 330)),
    _FocusKey(.28, 1.0, Offset(490, 330)), // full page loads, uncropped
    _FocusKey(.36, 2.0, Offset(730, 258)), // Alice's row: hours + net pay
    _FocusKey(.66, 2.0, Offset(730, 258)),
    _FocusKey(.74, 1.9, Offset(860, 190)), // the Save button click
    _FocusKey(.94, 1.9, Offset(860, 190)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(
          t: t,
          eyebrow: 'PAYSLIP MANAGER',
          head: 'Payroll in minutes,\nnot days.',
          sub: 'Hours in. PAYE, UIF and SARS-ready payslips out.\nNo spreadsheets. No errors.',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ClipRect(
            child: _In(
              t: t,
              start: .06,
              end: .20,
              from: const Offset(0, 110),
              scaleFrom: .96,
              child: _CameraStage(
                t: t,
                keys: _cam,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _DesktopFrame(
                      slug: 'payslip-manager',
                      title: 'Payslip Manager',
                      selected: 4,
                      child: _body(),
                    ),
                    Positioned.fill(
                      child: _Pointer(
                        t: t,
                        appear: .42,
                        path: const [
                          _PtKey(.42, Offset(650, 320)),
                          _PtKey(.52, Offset(774, 250)),
                          _PtKey(.62, Offset(774, 250)),
                          _PtKey(.78, Offset(877, 168)),
                          _PtKey(.92, Offset(877, 168)),
                        ],
                        clicks: const [.58, .84],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period bar — real date pills
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                _datePill(.16, 'Default Start', '1 Jun 26'),
                const SizedBox(width: 8),
                _datePill(.18, 'Default End', '30 Jun 26'),
                const SizedBox(width: 8),
                _datePill(.20, 'Pay Date', '25 Jun 26'),
                const SizedBox(width: 8),
                _datePill(.22, 'Employer UIF Reg Nr', '1234567/8'),
              ],
            ),
          ),
          // Action bar — real: grey50, search + Save Payslips green.shade700
          Container(
            height: 44, // fixed → Save button click position is exact
            color: _kGrey50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _In(
                  t: t,
                  start: .24,
                  from: const Offset(-20, 0),
                  child: Container(
                    width: 190,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kGrey300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, size: 14, color: _kGrey400),
                        SizedBox(width: 6),
                        Text(
                          'Search employees…',
                          style: TextStyle(fontSize: 11.5, color: _kGrey400),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _outlineBtn(.26, Icons.event_note_outlined, 'Leave Records'),
                const SizedBox(width: 6),
                _outlineBtn(.28, Icons.summarize_outlined, 'UIF Summary'),
                const SizedBox(width: 6),
                // Save button — real green.shade700, clicked at .84
                _In(
                  t: t,
                  start: .30,
                  from: const Offset(0, 14),
                  child: AnimatedBuilder(
                    animation: t,
                    builder: (_, __) {
                      final saved = _iv(t.value, .86, .92);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _kSaveGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              saved > .5
                                  ? Icons.check_circle
                                  : Icons.save_outlined,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              saved > .5
                                  ? 'Saved ✓'
                                  : 'Save Payslips (3)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Table header — real grey100 with 10px bold cols
          Container(
            height: 36, // fixed
            color: _kGrey100,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Expanded(flex: 22, child: Text('Employee', style: _th)),
                Expanded(flex: 13, child: Text('ID Number', style: _th)),
                Expanded(
                    flex: 9,
                    child: Text('Rate\n(R/hr)',
                        style: _th, textAlign: TextAlign.center)),
                Expanded(
                    flex: 6,
                    child: Text('Norm\nhrs',
                        style: _th, textAlign: TextAlign.center)),
                Expanded(
                    flex: 6,
                    child:
                        Text('OT\nhrs', style: _th, textAlign: TextAlign.center)),
                Expanded(
                    flex: 11,
                    child: Text('Net Pay',
                        style: _th, textAlign: TextAlign.right)),
                Expanded(
                    flex: 27,
                    child: Text('Payslip Period',
                        style: _th, textAlign: TextAlign.center)),
              ],
            ),
          ),
          _empRow(
            start: .20,
            name: 'Alice Mostert',
            id: '8503125009087',
            rate: '28.50',
            focus: true,
            odd: false,
          ),
          _empRow(
            start: .24,
            name: 'Brian Nkosi',
            id: '9107045233081',
            rate: '32.00',
            odd: true,
          ),
          _empRow(
            start: .28,
            name: 'Carol van Wyk',
            id: '8809210345086',
            rate: '25.00',
            odd: false,
          ),
        ],
      ),
    );
  }

  static const _th = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    height: 1.2,
  );

  Widget _datePill(double start, String label, String value) {
    return _In(
      t: t,
      start: start,
      from: const Offset(0, 14),
      child: Container(
        height: 34, // fixed → click coordinates are exact
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: _kGrey300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 11, color: Colors.black87),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 8.5, color: _kGrey400),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineBtn(double start, IconData icon, String label) {
    return _In(
      t: t,
      start: start,
      from: const Offset(0, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kGrey300),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empRow({
    required double start,
    required String name,
    required String id,
    required String rate,
    bool focus = false,
    required bool odd,
  }) {
    return _In(
      t: t,
      start: start,
      from: const Offset(40, 0),
      child: Container(
        height: 56, // fixed → nav-arrow click position is exact
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: odd ? _kGrey50 : Colors.white,
          border: Border(
            bottom: const BorderSide(color: _kGrey300, width: .6),
            left: focus
                ? const BorderSide(color: _kPrimary, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Employee: status dot + name + PERM chip + edit icon (real row)
            Expanded(
              flex: 22,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: focus ? _kSaveGreen : _kApproved,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: const Color(0xFFA5D6A7), width: .6),
                    ),
                    child: const Text(
                      'PERM',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 12, color: _kGrey),
                ],
              ),
            ),
            Expanded(
              flex: 13,
              child: Text(
                id,
                style: const TextStyle(fontSize: 11, color: _kGrey),
              ),
            ),
            Expanded(flex: 9, child: _field(rate, focus)),
            Expanded(
              flex: 6,
              child: _field(focus ? '176' : '160', focus,
                  typedAt: focus ? start + .14 : null),
            ),
            Expanded(
              flex: 6,
              child: _field(focus ? '8' : '4', focus,
                  typedAt: focus ? start + .20 : null),
            ),
            // Net pay — green.shade700 bold (real)
            Expanded(
              flex: 11,
              child: focus
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: _CountUp(
                        t: t,
                        start: start + .16,
                        end: start + .40,
                        from: 0,
                        to: 4820.97,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _kSaveGreen,
                        ),
                        formatter: _fmtR,
                      ),
                    )
                  : const Text(
                      'R 5 093.28',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _kSaveGreen,
                      ),
                    ),
            ),
            // Nav — real: 26px black87 circles, date 11 w600, counter badge
            Expanded(flex: 27, child: _periodNav(focus)),
          ],
        ),
      ),
    );
  }

  Widget _field(String value, bool focus, {double? typedAt}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: focus ? Colors.white : _kGrey100,
          border: Border.all(
            color: focus ? Colors.black87 : _kGrey300,
            width: focus ? 1.2 : 1,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: typedAt == null
            ? Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: focus ? Colors.black87 : _kGrey,
                ),
              )
            : AnimatedBuilder(
                animation: t,
                builder: (_, __) {
                  final u = _iv(t.value, typedAt, typedAt + .05);
                  return Opacity(
                    opacity: u,
                    child: Transform.scale(
                      scale: .6 + .4 * u,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _periodNav(bool focus) {
    Widget arrow(IconData icon) => Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
        child: Icon(icon, color: Colors.white, size: 15),
        );

    Widget period(String label, String counter) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _kGrey300.withOpacity(.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                counter,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: _kGrey,
                ),
              ),
            ),
          ],
        );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            arrow(Icons.chevron_left),
            const SizedBox(width: 4),
            if (!focus)
              period('1 Jun 26 – 30 Jun 26', '2/4')
            else
              AnimatedBuilder(
                animation: t,
                builder: (_, __) {
                  final u = _iv(t.value, .58, .66);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 1 - u,
                        child: Transform.translate(
                          offset: Offset(16 * u, 0),
                          child: period('1 Jun 26 – 30 Jun 26', '3/3'),
                        ),
                      ),
                      Opacity(
                        opacity: u,
                        child: Transform.translate(
                          offset: Offset(-16 * (1 - u), 0),
                          child: period('1 May 26 – 31 May 26', '2/3'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(width: 4),
            arrow(Icons.chevron_right),
          ],
        ),
        const SizedBox(height: 3),
        // Real icon row under the date
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 12, color: Colors.black87),
            SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 12, color: Colors.black87),
            SizedBox(width: 8),
            Icon(Icons.add_circle_outline, size: 12, color: Colors.black87),
            SizedBox(width: 8),
            Icon(Icons.remove_circle_outline, size: 12, color: Colors.black87),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, size: 12, color: _kGrey400),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE 6 — NOTIFICATIONS (faithful to notifications_screen.dart)
// ═══════════════════════════════════════════════════════════════════════════

class _NotifyScene extends StatelessWidget {
  const _NotifyScene({required this.t});
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(
          t: t,
          eyebrow: 'NOTIFICATIONS',
          head: 'Never miss\na deadline.',
          sub: 'Rejections, expiring documents and upcoming audits,\npushed to your phone the moment they happen.',
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 940,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    child: _In(
                      t: t,
                      start: .06,
                      end: .26,
                      scaleFrom: .4,
                      from: Offset.zero,
                      curve: Curves.easeOutBack,
                      child: _bell(),
                    ),
                  ),
                  Positioned(
                    top: 240,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        _toast(
                          .28,
                          Icons.cancel_outlined,
                          const Color(0xFFE53935),
                          const Color(0xFFFFEBEE),
                          'Document rejected',
                          'Analysis Potable Water: “E. coli detected, please retest.”',
                        ),
                        const SizedBox(height: 18),
                        _toast(
                          .44,
                          Icons.schedule,
                          const Color(0xFFF57C00),
                          const Color(0xFFFFF3E0),
                          'Expiring in 7 days',
                          'Chemical storage certificate, renew before 2 Jul.',
                        ),
                        const SizedBox(height: 18),
                        _toast(
                          .60,
                          Icons.event_note,
                          const Color(0xFF1976D2),
                          const Color(0xFFE3F2FD),
                          'Audit coming up',
                          'SIZA social audit in 30 days. You are 87% ready.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bell() {
    return AnimatedBuilder(
      animation: t,
      builder: (_, __) {
        double wiggle = 0;
        for (final at in [.34, .50, .66]) {
          final d = t.value - at;
          if (d > 0 && d < .09) {
            wiggle += math.sin(d / .09 * math.pi * 3) * (1 - d / .09) * .12;
          }
        }
        final count = t.value >= .66
            ? 3
            : t.value >= .50
                ? 2
                : t.value >= .34
                    ? 1
                    : 0;
        return Transform.rotate(
          angle: wiggle,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(.22),
                      blurRadius: 48,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications,
                  size: 96,
                  color: _kPrimary,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(count),
                    tween: Tween(begin: .4, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (_, s, c) => Transform.scale(scale: s, child: c),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _toast(
    double start,
    IconData icon,
    Color fg,
    Color bg,
    String title,
    String sub,
  ) {
    return _In(
      t: t,
      start: start,
      end: start + .13,
      from: const Offset(340, 0),
      child: Container(
        width: 780,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(.14),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 19, color: _kGrey),
                  ),
                ],
              ),
            ),
            const Text(
              'now',
              style: TextStyle(fontSize: 17, color: _kGrey400),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE 7 — OUTRO (+ static end frame)
// ═══════════════════════════════════════════════════════════════════════════

class _OutroScene extends StatelessWidget {
  const _OutroScene({required this.t});
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _In(
            t: t,
            start: .04,
            end: .30,
            scaleFrom: .4,
            from: Offset.zero,
            curve: Curves.easeOutBack,
            child: const _RealLogo(size: 170),
          ),
          const SizedBox(height: 50),
          _In(
            t: t,
            start: .18,
            from: const Offset(0, 44),
            child: const Text(
              'Get audit-ready\ntoday.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -2.5,
                color: _kInk,
              ),
            ),
          ),
          const SizedBox(height: 34),
          _In(
            t: t,
            start: .32,
            from: const Offset(0, 28),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusBadge('SIZA / WIETA', 0),
                SizedBox(width: 14),
                _StatusBadge('GlobalG.A.P.', 0),
                SizedBox(width: 14),
                _StatusBadge('IPW', 0),
              ],
            ),
          ),
          const SizedBox(height: 56),
          _In(
            t: t,
            start: .42,
            from: const Offset(0, 34),
            scaleFrom: .92,
            child: _cta(),
          ),
          const SizedBox(height: 24),
          _In(
            t: t,
            start: .52,
            from: const Offset(0, 20),
            child: const Text(
              'Book a demo →',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cta() {
    return AnimatedBuilder(
      animation: t,
      builder: (_, __) {
        final sheen = _iv(t.value, .55, .85, Curves.easeInOut);
        return ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Stack(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 58, vertical: 26),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(.4),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Text(
                  'crop-compliance.com',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(-500 + 1100 * sheen, 0),
                    child: Transform.rotate(
                      angle: .35,
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white.withOpacity(.35),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutroStatic extends StatelessWidget {
  const _OutroStatic();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _RealLogo(size: 170),
          const SizedBox(height: 50),
          const Text(
            'Get audit-ready\ntoday.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -2.5,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 34),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusBadge('SIZA / WIETA', 0),
              SizedBox(width: 14),
              _StatusBadge('GlobalG.A.P.', 0),
              SizedBox(width: 14),
              _StatusBadge('IPW', 0),
            ],
          ),
          const SizedBox(height: 56),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 58, vertical: 26),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(.4),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: const Text(
              'crop-compliance.com',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Book a demo →',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _kGrey,
            ),
          ),
        ],
      ),
    );
  }
}
