import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cropCompliance/core/constants/app_constants.dart';
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Service for the Farmable Partner API v2.0.
/// All calls use the single partner API key stored in AppConstants.
/// Base: https://api.farmable.tech  ·  Rate limit: 60/min on sales + job endpoints.
class FarmableService {
  static const _base = AppConstants.farmableBaseUrl;
  static const _headers = {
    'api-key': AppConstants.farmableApiKey,
    'Content-Type': 'application/json',
    'Accept': 'application/json', // l10n-ignore: header
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(
          queryParameters: (query != null && query.isNotEmpty) ? query : null);

  List<T> _list<T>(http.Response res, T Function(Map<String, dynamic>) fromJson) {
    _check(res);
    final List data = jsonDecode(res.body) as List;
    return data.map((j) => fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Farms / fields / sales ─────────────────────────────────────────────────

  Future<List<FarmableLocation>> getFarms() async =>
      _list(await http.get(_uri('/v1/farms'), headers: _headers),
          FarmableLocation.fromJson);

  /// Optionally filter client-side to a specific [farmId].
  Future<List<FarmableField>> getFields({int? farmId}) async {
    final all = _list(await http.get(_uri('/v1/fields'), headers: _headers),
        FarmableField.fromJson);
    return farmId == null ? all : all.where((f) => f.farmId == farmId).toList();
  }

  /// Optionally filter client-side to specific [fieldIds].
  Future<List<FarmableSale>> getSales({List<int>? fieldIds}) async {
    final all = _list(await http.get(_uri('/v1/sales'), headers: _headers),
        FarmableSale.fromJson)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (fieldIds != null && fieldIds.isNotEmpty) {
      return all
          .where((s) => s.fieldIds.any((id) => fieldIds.contains(id)))
          .toList();
    }
    return all;
  }

  // ── People ─────────────────────────────────────────────────────────────────

  Future<List<FarmableMember>> getFarmMembers() async =>
      _list(await http.get(_uri('/v1/farm-members'), headers: _headers),
          FarmableMember.fromJson);

  Future<List<FarmableTeam>> getTeams() async =>
      _list(await http.get(_uri('/v1/teams'), headers: _headers),
          FarmableTeam.fromJson);

  Future<List<FarmableTeamMember>> getTeamMembers() async =>
      _list(await http.get(_uri('/v1/team-members'), headers: _headers),
          FarmableTeamMember.fromJson);

  /// Optionally filter by date range (YYYY-MM-DD).
  Future<List<FarmableTimesheet>> getTimesheets(
      {String? dateFrom, String? dateTo}) async {
    final q = <String, String>{};
    if (dateFrom != null) q['dateFrom'] = dateFrom;
    if (dateTo != null) q['dateTo'] = dateTo;
    return _list(await http.get(_uri('/v1/timesheets', q), headers: _headers),
        FarmableTimesheet.fromJson);
  }

  // ── Equipment ──────────────────────────────────────────────────────────────

  Future<List<FarmableEquipment>> getEquipment({int? farmId}) async {
    final all = _list(await http.get(_uri('/v1/equipments'), headers: _headers),
        FarmableEquipment.fromJson);
    return farmId == null ? all : all.where((e) => e.farmId == farmId).toList();
  }

  // ── Reference / lookup data ────────────────────────────────────────────────

  Future<List<FarmableCrop>> getCrops() async =>
      _list(await http.get(_uri('/v1/crops'), headers: _headers),
          FarmableCrop.fromJson);

  Future<List<FarmableCropVariety>> getCropVarieties() async =>
      _list(await http.get(_uri('/v1/crop-varieties'), headers: _headers),
          FarmableCropVariety.fromJson);

  Future<List<FarmableJustification>> getJustifications() async =>
      _list(await http.get(_uri('/v1/justifications'), headers: _headers),
          FarmableJustification.fromJson);

  Future<List<FarmableCause>> getCauses() async =>
      _list(await http.get(_uri('/v1/causes'), headers: _headers),
          FarmableCause.fromJson);

  /// Optionally filter by CSV of [fieldIds].
  Future<List<FarmableTreatment>> getTreatments({List<int>? fieldIds}) async {
    final q = (fieldIds != null && fieldIds.isNotEmpty)
        ? {'fieldIds': fieldIds.join(',')}
        : null;
    return _list(await http.get(_uri('/v1/treatments', q), headers: _headers),
        FarmableTreatment.fromJson);
  }

  // ── Job weather ────────────────────────────────────────────────────────────

  Future<FarmableJobWeather> getJobWeather(int jobId) async {
    final res = await http.get(
        _uri('/v1/job-weather', {'jobId': '$jobId'}), headers: _headers);
    _check(res);
    return FarmableJobWeather.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Write: spray / fertilizer jobs ─────────────────────────────────────────

  /// Creates a spray job. Returns the new job id.
  Future<int> createSprayJob(SprayJobInput input) async {
    final res = await http.post(_uri('/v1/spray-jobs'),
        headers: _headers, body: jsonEncode(input.toJson()));
    _check(res);
    return ((jsonDecode(res.body) as Map<String, dynamic>)['id'] as num)
        .toInt();
  }

  /// Creates a fertilizer job. Returns the new job id.
  Future<int> createFertilizeJob(FertilizeJobInput input) async {
    final res = await http.post(_uri('/v1/fertilize-jobs'),
        headers: _headers, body: jsonEncode(input.toJson()));
    _check(res);
    return ((jsonDecode(res.body) as Map<String, dynamic>)['id'] as num)
        .toInt();
  }

  // ── Raw call (for the diagnostics console) ─────────────────────────────────

  /// Fires a raw GET and returns the status + (pretty-printed) body without
  /// throwing, so the console can display 500s and empty results directly.
  Future<FarmableRawResult> debugGet(String path,
      [Map<String, String>? query]) async {
    try {
      final res = await http.get(_uri(path, query), headers: _headers);
      String pretty = res.body;
      int? count;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is List) count = decoded.length;
        pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {/* leave body as-is */}
      return FarmableRawResult(
        status: res.statusCode,
        body: pretty,
        count: count,
        rateRemaining: res.headers['rate-limit-remaining'],
      );
    } catch (e) {
      return FarmableRawResult(status: -1, body: e.toString());
    }
  }

  // ── Error handling ─────────────────────────────────────────────────────────

  void _check(http.Response res) {
    if (res.statusCode == 401) throw FarmableException(LocaleProvider.instance.l10n.fmInvalidKey);
    if (res.statusCode == 403) throw FarmableException(LocaleProvider.instance.l10n.fmForbidden);
    if (res.statusCode == 404) throw FarmableException(LocaleProvider.instance.l10n.fmNotFound);
    if (res.statusCode == 429) {
      throw FarmableException(LocaleProvider.instance.l10n.fmRateLimit);
    }
    if (res.statusCode >= 400) {
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {}
      throw FarmableException(
          body?['message'] ?? LocaleProvider.instance.l10n.fmApiError(res.statusCode),
          errorId: body?['errorId']?.toString());
    }
  }
}

/// Result of a raw diagnostics call.
class FarmableRawResult {
  final int status; // -1 = client/network error
  final String body;
  final int? count; // list length when the body is a JSON array
  final String? rateRemaining;
  const FarmableRawResult({
    required this.status,
    required this.body,
    this.count,
    this.rateRemaining,
  });
  bool get ok => status >= 200 && status < 300;
}

class FarmableException implements Exception {
  final String message;
  final String? errorId;
  FarmableException(this.message, {this.errorId});
  @override
  String toString() =>
      'FarmableException: $message${errorId != null ? ' (errorId: $errorId)' : ''}'; // l10n-ignore: debug toString
}
