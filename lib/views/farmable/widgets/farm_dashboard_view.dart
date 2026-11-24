import 'dart:math' as math;
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:cropCompliance/views/farmable/widgets/farm_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Dense bento-style farm dashboard: neat light-grey cards packed tightly,
/// subtle radii, cohesive green + amber palette, with an interactive satellite
/// map tile. Pure presentation — data + callbacks are injected.
class FarmDashboardView extends StatelessWidget {
  final FarmableLocation? farm;
  final String companyName;
  final List<FarmableField> fields;
  final List<FarmableEquipment> equipment;
  final List<({FarmableMember member, String role})> people;
  final Map<String, Color> cropColors;
  final VoidCallback onSkyView;
  final VoidCallback onPdf;

  const FarmDashboardView({
    Key? key,
    required this.farm,
    required this.companyName,
    required this.fields,
    required this.equipment,
    required this.people,
    required this.cropColors,
    required this.onSkyView,
    required this.onPdf,
  }) : super(key: key);

  static final _num1 = NumberFormat('#,##0.0', 'en_ZA');
  static DateFormat get _dateFmt => DateFormat('d MMM yyyy'); // follows the app language

  // ── Palette ─────────────────────────────────────────────────────────────────
  static const _page = Color(0xFFEDECE6); // warm grey off-white background
  static const _card = Color(0xFFFFFFFF); // white cards
  static const _ink = Color(0xFF1C201B);
  static const _ink2 = Color(0xFF828779);
  static const _green = Color(0xFF43A047);
  static const _deepGreen = Color(0xFF2E7D32);
  static const _amber = Color(0xFFE79A2B);
  static const _orange = Color(0xFFE2703A);
  static const _line = Color(0xFFE7E8E2);

  static const _radius = 18.0;

  double get _totalHa => fields.fold<double>(0, (s, f) => s + f.areaHectares);
  int get _missing => equipment.where((e) => e.inspectionDate == null).length;
  int get _inspected => equipment.length - _missing;

  Map<String, double> get _cropAreas {
    final m = <String, double>{};
    for (final f in fields) {
      m.update(FarmMapView.cropOf(f), (v) => v + f.areaHectares,
          ifAbsent: () => f.areaHectares);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _page,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 940;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          child: wide ? _wide() : _narrow(),
        );
      }),
    );
  }

  // ── Wide bento layout ───────────────────────────────────────────────────────
  Widget _wide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 440,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left rail
              SizedBox(
                width: 320,
                child: Column(children: [
                  Expanded(
                    flex: 2,
                    child: Row(children: [
                      Expanded(child: _statArea()),
                      const SizedBox(width: 12),
                      Expanded(child: _statFields()),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 2,
                    child: Row(children: [
                      Expanded(child: _statCrops()),
                      const SizedBox(width: 12),
                      Expanded(child: _statPeople()),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Expanded(flex: 3, child: _inspectionGauge()),
                ]),
              ),
              const SizedBox(width: 12),
              // Map
              Expanded(child: _mapTile()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _cropCard()),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: _equipmentCard()),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: _peopleCard()),
            ],
          ),
        ),
      ],
    );
  }

  // ── Narrow layout ───────────────────────────────────────────────────────────
  Widget _narrow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 300, child: _mapTile()),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SizedBox(height: 130, child: _statArea())),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 130, child: _statFields())),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SizedBox(height: 130, child: _statCrops())),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 130, child: _statPeople())),
        ]),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _inspectionGauge()),
        const SizedBox(height: 12),
        SizedBox(height: 230, child: _cropCard()),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _equipmentCard()),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _peopleCard()),
      ],
    );
  }

  // ── Stat tiles ──────────────────────────────────────────────────────────────
  Widget _statArea() => _statTile(Icons.eco_outlined, _num1.format(_totalHa),
      'ha', LocaleProvider.instance.l10n.fmTotalArea);
  Widget _statFields() => _statTile(Icons.grid_view_rounded,
      '${fields.length}', LocaleProvider.instance.l10n.unitBlocks, LocaleProvider.instance.l10n.fmFields);
  Widget _statCrops() => _statTile(Icons.spa_outlined,
      '${cropColors.length}', LocaleProvider.instance.l10n.unitTypes, LocaleProvider.instance.l10n.fmCropTypes);
  Widget _statPeople() => _statTile(Icons.groups_outlined,
      '${people.length}', LocaleProvider.instance.l10n.unitMembers, LocaleProvider.instance.l10n.fmPeople);

  Widget _statTile(IconData icon, String value, String unit, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(_radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _green.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: _deepGreen),
          ),
          // Fill the rest and scale the value/label block down if space is
          // ever tight — guarantees no overflow at any card height.
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(value,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                height: 1)),
                        const SizedBox(width: 5),
                        Text(unit,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _ink2)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(label,
                        style: const TextStyle(fontSize: 11.5, color: _ink2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Inspection gauge ────────────────────────────────────────────────────────
  Widget _inspectionGauge() {
    final total = equipment.length;
    final pct = total == 0 ? 0.0 : _inspected / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(_radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: _amber.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(9)),
              child:
                  const Icon(Icons.verified_outlined, size: 16, color: _amber),
            ),
            const SizedBox(width: 8),
            Text(LocaleProvider.instance.l10n.fmEquipmentInspection,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink)),
          ]),
          Expanded(
            child: Center(
              child: total == 0
                  ? Text(LocaleProvider.instance.l10n.fmNoEquipment,
                      style: TextStyle(color: _ink2, fontSize: 12))
                  : _SemiGauge(
                      value: pct,
                      color: _missing == 0 ? _green : _amber,
                      centerTop: '${(pct * 100).round()}%',
                      centerBottom: _missing == 0
                          ? LocaleProvider.instance.l10n.fmAllInspected
                          : LocaleProvider.instance.l10n.fmNeedInspection(_missing),
                      centerBottomColor: _missing == 0 ? _green : _orange,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map tile ────────────────────────────────────────────────────────────────
  Widget _mapTile() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          fields.isEmpty
              ? Container(color: const Color(0xFF223027))
              : _HeroMap(fields: fields, cropColors: cropColors),
          // top gradient for chip legibility
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.28),
                      Colors.transparent
                    ],
                    stops: const [0, 0.35],
                  ),
                ),
              ),
            ),
          ),
          // Farm label
          Positioned(
            left: 14,
            top: 12,
            right: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(farm?.displayName ?? companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8)
                        ])),
                Text(
                  LocaleProvider.instance.l10n.fmBlocksArea(fields.length, _num1.format(_totalHa)),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          // Actions
          Positioned(
            top: 12,
            right: 12,
            child: Row(children: [
              _circleBtn(Icons.open_in_full, onSkyView),
              const SizedBox(width: 8),
              _circleBtn(Icons.file_download_outlined, onPdf),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
            width: 38, height: 38, child: Icon(icon, size: 18, color: _deepGreen)),
      ),
    );
  }

  // ── Crop distribution ───────────────────────────────────────────────────────
  Widget _cropCard() {
    final areas = _cropAreas;
    final total = areas.values.fold<double>(0, (s, v) => s + v);
    final entries = areas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _bentoCard(
      title: LocaleProvider.instance.l10n.fmCropDistribution,
      icon: Icons.donut_small_outlined,
      child: entries.isEmpty || total <= 0
          ? _empty(LocaleProvider.instance.l10n.fmNoCropData)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 16,
                    child: Row(children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          flex: (entries[i].value / total * 1000)
                              .round()
                              .clamp(1, 1000000),
                          child: Container(
                              color: cropColors[entries[i].key] ?? _green),
                        ),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final pct = e.value / total * 100;
                      return Row(children: [
                        Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                                color: cropColors[e.key] ?? _green,
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _ink)),
                        ),
                        Text(LocaleProvider.instance.l10n.fmHectares(_num1.format(e.value)),
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 38,
                          child: Text('${pct.toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12, color: _ink2)),
                        ),
                      ]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ── Equipment ───────────────────────────────────────────────────────────────
  Widget _equipmentCard() {
    return _bentoCard(
      title: LocaleProvider.instance.l10n.fmEquipment,
      icon: Icons.agriculture_outlined,
      trailing: _missing > 0
          ? _pill(LocaleProvider.instance.l10n.fmToInspect(_missing), _orange)
          : _pill(LocaleProvider.instance.l10n.fmAllGood, _green),
      child: equipment.isEmpty
          ? _empty(LocaleProvider.instance.l10n.fmNoEquipmentRecord)
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: equipment.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 16, color: _line),
              itemBuilder: (_, i) => _equipmentRow(equipment[i]),
            ),
    );
  }

  Widget _equipmentRow(FarmableEquipment e) {
    final noInsp = e.inspectionDate == null;
    return Row(children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: _amber.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.agriculture_outlined,
            size: 17, color: Color(0xFFB47500)),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.name.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
            Text(
                noInsp
                    ? e.equipmentType
                    : LocaleProvider.instance.l10n.fmInspectedOn(_dateFmt.format(e.inspectionDate!)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _ink2)),
          ],
        ),
      ),
      const SizedBox(width: 6),
      noInsp
          ? _pill(LocaleProvider.instance.l10n.fmDue, _orange)
          : _pill(LocaleProvider.instance.l10n.tsOk, _green),
    ]);
  }

  // ── People ──────────────────────────────────────────────────────────────────
  Widget _peopleCard() {
    return _bentoCard(
      title: LocaleProvider.instance.l10n.fmPeopleRoles,
      icon: Icons.groups_outlined,
      trailing: _pill('${people.length}', _green),
      child: people.isEmpty
          ? _empty(LocaleProvider.instance.l10n.fmNoPeople)
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: people.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 16, color: _line),
              itemBuilder: (_, i) => _personRow(people[i]),
            ),
    );
  }

  Widget _personRow(({FarmableMember member, String role}) p) {
    final initial =
        p.member.fullName.isNotEmpty ? p.member.fullName[0].toUpperCase() : '?';
    return Row(children: [
      Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [_green, _deepGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        alignment: Alignment.center,
        child: Text(initial,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.member.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
            Text(p.member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _ink2)),
          ],
        ),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: _green.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20)),
        child: Text(p.role,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _deepGreen)),
      ),
    ]);
  }

  // ── Shared ──────────────────────────────────────────────────────────────────
  Widget _bentoCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(_radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: _green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 16, color: _deepGreen),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.2)),
            ),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _empty(String msg) => Center(
        child: Text(msg, style: const TextStyle(fontSize: 13, color: _ink2)),
      );
}

// ── Semicircular gauge ────────────────────────────────────────────────────────
class _SemiGauge extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final String centerTop;
  final String centerBottom;
  final Color centerBottomColor;
  const _SemiGauge({
    required this.value,
    required this.color,
    required this.centerTop,
    required this.centerBottom,
    required this.centerBottomColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Constrain by BOTH width and available height so it never overflows.
      final maxByHeight =
          c.maxHeight.isFinite ? c.maxHeight / 0.62 : double.infinity;
      final w = math.min(math.min(c.maxWidth, maxByHeight), 220.0);
      return SizedBox(
        width: w,
        height: w * 0.62,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(
              size: Size(w, w * 0.55),
              painter: _GaugePainter(value: value, color: color),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(centerTop,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C201B),
                          height: 1)),
                  const SizedBox(height: 2),
                  Text(centerBottom,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: centerBottomColor)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2,
        size.width - stroke, (size.height * 2) - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE2E4DD);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    // 180° arc across the top (pi → 2pi)
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    canvas.drawArc(
        rect, math.pi, math.pi * value.clamp(0.0, 1.0), false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}

/// Interactive satellite hero: pinch/scroll/drag to zoom & pan inline, plus
/// dedicated +/- controls.
class _HeroMap extends StatefulWidget {
  final List<FarmableField> fields;
  final Map<String, Color> cropColors;
  const _HeroMap({required this.fields, required this.cropColors});

  @override
  State<_HeroMap> createState() => _HeroMapState();
}

class _HeroMapState extends State<_HeroMap> {
  final _controller = MapController();

  void _zoom(double delta) {
    final cam = _controller.camera;
    _controller.move(cam.center, (cam.zoom + delta).clamp(3.0, 19.0));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FarmMapView(
          fields: widget.fields,
          cropColors: widget.cropColors,
          interactive: true,
          showLabels: true,
          controller: _controller,
          fitPadding:
              const EdgeInsets.only(top: 64, bottom: 40, left: 40, right: 40),
        ),
        Positioned(
          left: 12,
          bottom: 14,
          child: Column(children: [
            _zoomBtn(Icons.add, () => _zoom(1)),
            const SizedBox(height: 8),
            _zoomBtn(Icons.remove, () => _zoom(-1)),
          ]),
        ),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 19, color: const Color(0xFF2E7D32))),
      ),
    );
  }
}
