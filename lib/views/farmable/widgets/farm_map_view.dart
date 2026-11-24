import 'package:cropCompliance/models/farmable_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// A field paired with its parsed boundary + centroid + crop.
class FarmBlock {
  final FarmableField field;
  final List<LatLng> ring;
  final LatLng centroid;
  final String crop;
  FarmBlock(this.field, this.ring, this.centroid, this.crop);
}

/// Reusable satellite map of a farm's fields, drawn as real boundary polygons
/// (from Farmable `wktGeometry`) over Esri World Imagery. Shared by the Farm
/// Register hero (non-interactive) and the full "Sky View" screen.
class FarmMapView extends StatelessWidget {
  final List<FarmableField> fields;
  final Map<String, Color> cropColors;
  final bool interactive;
  final bool showLabels;
  final void Function(FarmableField field)? onTapField;
  final EdgeInsets fitPadding;
  final double borderRadius;
  final MapController? controller;

  const FarmMapView({
    Key? key,
    required this.fields,
    required this.cropColors,
    this.interactive = true,
    this.showLabels = true,
    this.onTapField,
    this.fitPadding = const EdgeInsets.all(36),
    this.borderRadius = 0,
    this.controller,
  }) : super(key: key);

  // Warm, earthy, on-brand palette (greens + amber + terracotta) — distinct on
  // green satellite imagery while staying cohesive with the app's green/amber
  // theme. Ordered for maximum separation on the first few slots.
  static const List<Color> cropPalette = [
    Color(0xFFF5B301), // gold/amber
    Color(0xFFE4703A), // terracotta
    Color(0xFF2E7D32), // forest green
    Color(0xFF1FA98C), // teal
    Color(0xFFC94F8A), // muted rose
    Color(0xFF8D6E63), // clay
    Color(0xFF9E9D24), // olive
    Color(0xFF5C6BC0), // dusty indigo
  ];

  static String cropOf(FarmableField f) => f.varieties.isEmpty
      ? LocaleProvider.instance.l10n.fmUnassigned
      : f.varieties.map((v) => v.categoryName).firstWhere(
          (c) => c.isNotEmpty,
          orElse: () => LocaleProvider.instance.l10n.fmUnassigned);

  /// Stable crop→color assignment (alphabetical → fixed palette slots).
  static Map<String, Color> cropColorsFor(List<FarmableField> fields) {
    final crops = <String>{for (final f in fields) cropOf(f)}.toList()..sort();
    final map = <String, Color>{};
    for (var i = 0; i < crops.length; i++) {
      map[crops[i]] = cropPalette[i % cropPalette.length];
    }
    return map;
  }

  /// Parses the first (outer) ring of a WKT POLYGON/MULTIPOLYGON.
  /// WKT is "lng lat" order → LatLng(lat, lng).
  static List<LatLng> parseFirstRing(String? wkt) {
    if (wkt == null || wkt.isEmpty) return const [];
    final open = wkt.indexOf('((');
    if (open < 0) return const [];
    final close = wkt.indexOf(')', open);
    if (close < 0) return const [];
    final ring = wkt.substring(open + 2, close).replaceAll('(', '');
    final pts = <LatLng>[];
    for (final pair in ring.split(',')) {
      final nums = pair.trim().split(RegExp(r'\s+'));
      if (nums.length >= 2) {
        final lng = double.tryParse(nums[0]);
        final lat = double.tryParse(nums[1]);
        if (lng != null && lat != null) pts.add(LatLng(lat, lng));
      }
    }
    return pts;
  }

  /// A subtle block-name badge with a rich hover card (block, ha, crop/variety).
  /// Hover shows on desktop/web; long-press shows it on touch. Tapping still
  /// fires [onTapField] when provided.
  Widget _blockBadge(FarmBlock b) {
    final color = cropColors[b.crop] ?? Colors.green;
    final variety = b.field.varieties.isEmpty
        ? ''
        : b.field.varieties.map((v) => v.name).join(', ');
    final area = b.field.areaHectares.toStringAsFixed(2);

    // Subtle location dot (no text) — hover reveals the info card below.
    final badge = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 3),
            ],
          ),
        ),
      ),
    );

    return Tooltip(
      waitDuration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xF01D211B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10),
        ],
      ),
      richMessage: TextSpan(
        style: const TextStyle(height: 1.35),
        children: [
          TextSpan(
              text: '${b.field.name.trim()}\n',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          TextSpan(
              text: LocaleProvider.instance.l10n.fmHectares(area),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          TextSpan(
              text: '   ·   ',
              style: TextStyle(color: Colors.white.withOpacity(0.5))),
          TextSpan(
              text: variety.isNotEmpty ? '${b.crop} · $variety' : b.crop,
              style: const TextStyle(color: Color(0xFFCFE8CF), fontSize: 12)),
        ],
      ),
      child: onTapField == null
          ? badge
          : GestureDetector(onTap: () => onTapField!(b.field), child: badge),
    );
  }

  static LatLng _centroid(List<LatLng> ring) {
    double lat = 0, lng = 0;
    for (final p in ring) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / ring.length, lng / ring.length);
  }

  List<FarmBlock> get _blocks {
    final out = <FarmBlock>[];
    for (final f in fields) {
      final ring = parseFirstRing(f.wktGeometry);
      if (ring.length < 3) continue;
      final centroid =
          f.centroid != null ? LatLng(f.centroid!.y, f.centroid!.x) : _centroid(ring);
      out.add(FarmBlock(f, ring, centroid, cropOf(f)));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks;
    if (blocks.isEmpty) {
      return Container(
        color: const Color(0xFF20303A),
        alignment: Alignment.center,
        child: Text(LocaleProvider.instance.l10n.fmNoMappedFields,
            style: TextStyle(color: Colors.white70)),
      );
    }
    final allPoints = [for (final b in blocks) ...b.ring];
    final bounds = LatLngBounds.fromPoints(allPoints);

    final map = FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCameraFit:
            CameraFit.bounds(bounds: bounds, padding: fitPadding),
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.cropcompliance.app',
          maxNativeZoom: 19,
        ),
        PolygonLayer(
          polygons: [
            for (final b in blocks)
              Polygon(
                points: b.ring,
                color: (cropColors[b.crop] ?? Colors.green).withOpacity(0.32),
                borderColor: cropColors[b.crop] ?? Colors.green,
                borderStrokeWidth: 2,
              ),
          ],
        ),
        if (showLabels)
          MarkerLayer(
            markers: [
              for (final b in blocks)
                Marker(
                  point: b.centroid,
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  child: _blockBadge(b),
                ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
                'Esri — World Imagery (Maxar, Earthstar Geographics)'), // l10n-ignore: map attribution
          ],
        ),
      ],
    );

    if (borderRadius > 0) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius), child: map);
    }
    return map;
  }
}
