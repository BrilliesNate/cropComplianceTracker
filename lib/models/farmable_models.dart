import 'package:cropCompliance/providers/locale_provider.dart';
/// Data models for the Farmable Partner API v2.0.
/// Parsers are built from real API responses (fields that the API omits or
/// sends as null are handled defensively). Unknown extra keys are ignored.

// ── Shared helpers ───────────────────────────────────────────────────────────

double? _toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
DateTime? _toDate(dynamic v) =>
    (v is String && v.isNotEmpty) ? DateTime.tryParse(v) : null;
List<int> _toIntList(dynamic v) =>
    (v as List? ?? []).map((e) => (e as num).toInt()).toList();
List<String> _toStrList(dynamic v) =>
    (v as List? ?? []).map((e) => e.toString()).toList();

/// A geographic point ({x: lng, y: lat}).
class FarmableCoordinate {
  final double x;
  final double y;
  const FarmableCoordinate({required this.x, required this.y});
  factory FarmableCoordinate.fromJson(Map<String, dynamic> j) =>
      FarmableCoordinate(
        x: (j['x'] as num?)?.toDouble() ?? 0,
        y: (j['y'] as num?)?.toDouble() ?? 0,
      );
}

// ── Farms ────────────────────────────────────────────────────────────────────

class FarmableLocation {
  final int id;
  final String name;
  final String? businessName;
  final String? vatNumber;
  final String? address;
  final String? city;
  final String? zip;
  final String? country;
  final String? timeZone;
  final String? seasonCutoffDate;
  final DateTime? createdAt;
  final FarmableCoordinate? coordinate;
  final FarmableMember? farmOwner;
  final List<String> productionMethods;

  FarmableLocation({
    required this.id,
    required this.name,
    this.businessName,
    this.vatNumber,
    this.address,
    this.city,
    this.zip,
    this.country,
    this.timeZone,
    this.seasonCutoffDate,
    this.createdAt,
    this.coordinate,
    this.farmOwner,
    this.productionMethods = const [],
  });

  factory FarmableLocation.fromJson(Map<String, dynamic> json) =>
      FarmableLocation(
        id: (json['id'] as num).toInt(),
        name: json['name'] ?? '',
        businessName: json['businessName'],
        vatNumber: json['vatNumber'],
        address: json['address'],
        city: json['city'],
        zip: json['zip'],
        country: json['country'],
        timeZone: json['timeZone'],
        seasonCutoffDate: json['seasonCutoffDate'],
        createdAt: _toDate(json['createdAt']),
        coordinate: json['coordinate'] is Map
            ? FarmableCoordinate.fromJson(
                json['coordinate'] as Map<String, dynamic>)
            : null,
        farmOwner: json['farmOwner'] is Map
            ? FarmableMember.fromJson(json['farmOwner'] as Map<String, dynamic>)
            : null,
        productionMethods: _toStrList(json['productionMethods']),
      );

  String get displayName =>
      businessName?.isNotEmpty == true ? businessName! : name;
}

// ── Fields ───────────────────────────────────────────────────────────────────

class FarmableField {
  final int id;
  final int farmId;
  final String name;
  final double areaSize; // square metres
  final String fieldType;
  final FarmableCoordinate? centroid;
  final String? wktGeometry;
  final List<FarmableVariety> varieties;

  FarmableField({
    required this.id,
    required this.farmId,
    required this.name,
    required this.areaSize,
    required this.fieldType,
    this.centroid,
    this.wktGeometry,
    required this.varieties,
  });

  /// Area in hectares (API returns square metres).
  double get areaHectares => areaSize / 10000.0;

  factory FarmableField.fromJson(Map<String, dynamic> json) => FarmableField(
        id: (json['id'] as num).toInt(),
        farmId: (json['farmId'] as num).toInt(),
        name: json['name'] ?? '',
        areaSize: (json['areaSize'] ?? 0.0).toDouble(),
        fieldType: json['fieldType'] ?? '',
        centroid: json['centroid'] is Map
            ? FarmableCoordinate.fromJson(
                json['centroid'] as Map<String, dynamic>)
            : null,
        wktGeometry: json['wktGeometry'],
        varieties: (json['varieties'] as List? ?? [])
            .map((v) => FarmableVariety.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class FarmableVariety {
  final String id;
  final String name;
  final String categoryName;
  final int percentage;
  final DateTime? sowDate;

  FarmableVariety({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.percentage,
    this.sowDate,
  });

  factory FarmableVariety.fromJson(Map<String, dynamic> json) =>
      FarmableVariety(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        categoryName:
            (json['category'] as Map<String, dynamic>?)?['name'] ?? '',
        percentage: (json['percentage'] ?? 0) as int,
        sowDate: _toDate(json['sowDate']),
      );
}

// ── Sales ────────────────────────────────────────────────────────────────────

class FarmableSale {
  final int id;
  final DateTime date;
  final String variety;
  final double? volume;
  final double? boxSize;
  final double? boxVolume;
  final int? pieceCount;
  final String countingUnit;
  final String categoryName;
  final List<int> fieldIds;
  final List<DateTime> harvestDates;

  FarmableSale({
    required this.id,
    required this.date,
    required this.variety,
    this.volume,
    this.boxSize,
    this.boxVolume,
    this.pieceCount,
    required this.countingUnit,
    required this.categoryName,
    required this.fieldIds,
    required this.harvestDates,
  });

  factory FarmableSale.fromJson(Map<String, dynamic> json) => FarmableSale(
        id: (json['id'] as num).toInt(),
        date: DateTime.parse(json['date']),
        variety: json['variety'] ?? '',
        volume: _toDouble(json['volume']),
        boxSize: _toDouble(json['boxSize']),
        boxVolume: _toDouble(json['boxVolume']),
        pieceCount: (json['pieceCount'] as num?)?.toInt(),
        countingUnit: json['countingUnit'] ?? 'WEIGHT',
        categoryName: (json['category'] as Map<String, dynamic>?)?['name'] ?? '',
        fieldIds: _toIntList(json['fieldIds']),
        harvestDates: (json['harvestDates'] as List? ?? [])
            .map((d) => DateTime.parse(d as String))
            .toList(),
      );

  String get volumeDisplay {
    if (countingUnit == 'BOXES' && boxVolume != null) {
      return LocaleProvider.instance.l10n.unitBoxes(boxVolume!.toStringAsFixed(1));
    }
    if (countingUnit == 'PIECES' && pieceCount != null) {
      return LocaleProvider.instance.l10n.unitPieces(pieceCount!);
    }
    if (volume != null) return '${volume!.toStringAsFixed(1)} kg'; // l10n-ignore: unit
    return '-';
  }
}

// ── Farm members ─────────────────────────────────────────────────────────────

class FarmableMember {
  final int id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? mobilePhone;
  final Map<String, String> roles; // { farmId: role }

  FarmableMember({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    this.mobilePhone,
    this.roles = const {},
  });

  String get fullName => [firstName, lastName]
      .where((s) => s != null && s.isNotEmpty)
      .join(' ');

  factory FarmableMember.fromJson(Map<String, dynamic> json) => FarmableMember(
        id: (json['id'] as num).toInt(),
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'],
        email: json['email'] ?? '',
        mobilePhone: json['mobilePhone'],
        roles: (json['roles'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
      );
}

// ── Equipment ────────────────────────────────────────────────────────────────

class FarmableEquipment {
  final int id;
  final int farmId;
  final String name;
  final String equipmentType;
  final String? registrationNumber;
  final DateTime? inspectionDate;
  final String? rate; // API sends strings e.g. 450.0 liters/hectare
  final String? tankSize; // e.g. 1000.0 liters
  final bool ownEquipment;
  final String? externalSource;

  FarmableEquipment({
    required this.id,
    required this.farmId,
    required this.name,
    required this.equipmentType,
    this.registrationNumber,
    this.inspectionDate,
    this.rate,
    this.tankSize,
    this.ownEquipment = true,
    this.externalSource,
  });

  factory FarmableEquipment.fromJson(Map<String, dynamic> json) =>
      FarmableEquipment(
        id: (json['id'] as num).toInt(),
        farmId: (json['farmId'] as num).toInt(),
        name: json['name'] ?? '',
        equipmentType: json['equipmentType'] ?? '',
        registrationNumber: json['registrationNumber'],
        inspectionDate: _toDate(json['inspectionDate']),
        rate: json['rate']?.toString(),
        tankSize: json['tankSize']?.toString(),
        ownEquipment: json['ownEquipment'] ?? true,
        externalSource: json['externalSource'],
      );
}

// ── Crops ────────────────────────────────────────────────────────────────────

class FarmableCrop {
  final String id;
  final String name;
  final String? label;
  final String? categoryType;
  final String? categoryGroup;
  final String? eppoCode;

  FarmableCrop({
    required this.id,
    required this.name,
    this.label,
    this.categoryType,
    this.categoryGroup,
    this.eppoCode,
  });

  factory FarmableCrop.fromJson(Map<String, dynamic> json) => FarmableCrop(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        label: json['label'],
        categoryType: json['categoryType'],
        categoryGroup: json['categoryGroup'],
        eppoCode: json['eppoCode'],
      );
}

// ── Crop varieties ───────────────────────────────────────────────────────────

class FarmableCropVariety {
  final String id;
  final String name;
  final String? cropId;
  final int? fieldId;
  final int percentage;
  final DateTime? sowDate;

  FarmableCropVariety({
    required this.id,
    required this.name,
    this.cropId,
    this.fieldId,
    this.percentage = 0,
    this.sowDate,
  });

  factory FarmableCropVariety.fromJson(Map<String, dynamic> json) =>
      FarmableCropVariety(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        cropId: json['cropId']?.toString(),
        fieldId: (json['fieldId'] as num?)?.toInt(),
        percentage: (json['percentage'] ?? 0) as int,
        sowDate: _toDate(json['sowDate']),
      );
}

// ── Justifications (SIEX) ────────────────────────────────────────────────────

class FarmableJustification {
  final String id;
  final String name;
  final String? description;
  final int? siexCode;

  FarmableJustification({
    required this.id,
    required this.name,
    this.description,
    this.siexCode,
  });

  factory FarmableJustification.fromJson(Map<String, dynamic> json) =>
      FarmableJustification(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        siexCode: (json['siexCode'] as num?)?.toInt(),
      );
}

// ── Causes (pest/disease) ────────────────────────────────────────────────────

class FarmableCause {
  final String? id;
  final String? scientificName; // nombreCientifico
  final String? eppoCode; // codigoEPPO
  final String? siexCode; // codigoSIEX

  FarmableCause({this.id, this.scientificName, this.eppoCode, this.siexCode});

  factory FarmableCause.fromJson(Map<String, dynamic> json) => FarmableCause(
        id: json['id']?.toString(),
        scientificName: json['nombreCientifico'],
        eppoCode: json['codigoEPPO']?.toString(),
        siexCode: json['codigoSIEX']?.toString(),
      );
}

// ── Treatments (products) ────────────────────────────────────────────────────

class FarmableTreatment {
  final String id;
  final String name;
  final int? farmId;
  final String? categoryId;
  final String? categoryName;
  final String? type;
  final String? registrationNumber;
  final double? amount;
  final String? unit;

  FarmableTreatment({
    required this.id,
    required this.name,
    this.farmId,
    this.categoryId,
    this.categoryName,
    this.type,
    this.registrationNumber,
    this.amount,
    this.unit,
  });

  factory FarmableTreatment.fromJson(Map<String, dynamic> json) =>
      FarmableTreatment(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        farmId: (json['farmId'] as num?)?.toInt(),
        categoryId: json['categoryId']?.toString(),
        categoryName: json['categoryName'],
        type: json['type'],
        registrationNumber: json['registrationNumber']?.toString(),
        amount: _toDouble(json['amount']),
        unit: json['unit'],
      );
}

// ── Teams / team members ─────────────────────────────────────────────────────

class FarmableTeam {
  final int id;
  final int? farmId;
  final String name;
  final int? teamLeadId;

  FarmableTeam({
    required this.id,
    this.farmId,
    required this.name,
    this.teamLeadId,
  });

  factory FarmableTeam.fromJson(Map<String, dynamic> json) => FarmableTeam(
        id: (json['id'] as num).toInt(),
        farmId: (json['farmId'] as num?)?.toInt(),
        name: json['name'] ?? '',
        teamLeadId: (json['teamLeadId'] as num?)?.toInt(),
      );
}

class FarmableTeamMember {
  final int id;
  final int? farmId;
  final int? teamId;
  final String fullName;
  final String? position;
  final String? customId;

  FarmableTeamMember({
    required this.id,
    this.farmId,
    this.teamId,
    required this.fullName,
    this.position,
    this.customId,
  });

  factory FarmableTeamMember.fromJson(Map<String, dynamic> json) =>
      FarmableTeamMember(
        id: (json['id'] as num).toInt(),
        farmId: (json['farmId'] as num?)?.toInt(),
        teamId: (json['teamId'] as num?)?.toInt(),
        fullName: json['fullName'] ?? '',
        position: json['position'],
        customId: json['customId']?.toString(),
      );
}

// ── Timesheets ───────────────────────────────────────────────────────────────

class FarmableTimesheet {
  final int id;
  final int? farmId;
  final int? teamId;
  final String? teamName;
  final int? teamMemberId;
  final String? teamMemberName;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final List<int> fieldIds;
  final String? comment;

  FarmableTimesheet({
    required this.id,
    this.farmId,
    this.teamId,
    this.teamName,
    this.teamMemberId,
    this.teamMemberName,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.fieldIds = const [],
    this.comment,
  });

  factory FarmableTimesheet.fromJson(Map<String, dynamic> json) =>
      FarmableTimesheet(
        id: (json['id'] as num).toInt(),
        farmId: (json['farmId'] as num?)?.toInt(),
        teamId: (json['teamId'] as num?)?.toInt(),
        teamName: json['teamName'],
        teamMemberId: (json['teamMemberId'] as num?)?.toInt(),
        teamMemberName: json['teamMemberName'],
        startTime: _toDate(json['startTime']),
        endTime: _toDate(json['endTime']),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
        fieldIds: _toIntList(json['fieldIds']),
        comment: json['comment'],
      );
}

// ── Job weather ──────────────────────────────────────────────────────────────

class FarmableJobWeather {
  final int? jobId;
  final DateTime? loggedAt;
  final String? source;
  final double? temperature;
  final double? precipitation;
  final double? windSpeed;
  final String? windDirection;

  FarmableJobWeather({
    this.jobId,
    this.loggedAt,
    this.source,
    this.temperature,
    this.precipitation,
    this.windSpeed,
    this.windDirection,
  });

  factory FarmableJobWeather.fromJson(Map<String, dynamic> json) =>
      FarmableJobWeather(
        jobId: (json['jobId'] as num?)?.toInt(),
        loggedAt: _toDate(json['loggedAt']),
        source: json['source'],
        temperature: _toDouble(json['temperature']),
        precipitation: _toDouble(json['precipitation']),
        windSpeed: _toDouble(json['windSpeed']),
        windDirection: json['windDirection']?.toString(),
      );
}

// ── POST inputs (write) ──────────────────────────────────────────────────────

/// One product application inside a spray/fertilizer job (TreatmentInputV1).
/// NOTE: the docs collapse this object; exact field names should be confirmed
/// against Farmable once the `treatments` endpoint is live. Kept flexible.
class TreatmentInput {
  final String treatmentId;
  final double amount;
  final String? unit;

  TreatmentInput({required this.treatmentId, required this.amount, this.unit});

  Map<String, dynamic> toJson() => {
        'treatmentId': treatmentId,
        'amount': amount,
        if (unit != null) 'unit': unit,
      };
}

/// Body for POST /v1/spray-jobs.
class SprayJobInput {
  final int farmId;
  final List<int> fields;
  final int memberId;
  final int equipmentId;
  final List<String> causeIds; // uuids
  final List<String> justificationIds; // uuids
  final List<TreatmentInput> treatments;
  final DateTime startDate;
  final DateTime? completedDate;

  SprayJobInput({
    required this.farmId,
    required this.fields,
    required this.memberId,
    required this.equipmentId,
    required this.causeIds,
    required this.justificationIds,
    required this.treatments,
    required this.startDate,
    this.completedDate,
  });

  static String _d(DateTime d) => d.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() => {
        'farmId': farmId,
        'fields': fields,
        'memberId': memberId,
        'equipmentId': equipmentId,
        'causeIds': causeIds,
        'justificationIds': justificationIds,
        'treatments': treatments.map((t) => t.toJson()).toList(),
        'startDate': _d(startDate),
        if (completedDate != null) 'completedDate': _d(completedDate!),
      };
}

/// Body for POST /v1/fertilize-jobs.
class FertilizeJobInput {
  final int farmId;
  final List<int> fields;
  final int memberId;
  final List<TreatmentInput> treatments;
  final DateTime startDate;
  final DateTime? completedDate;
  final String? documentOnSewageSludge;

  FertilizeJobInput({
    required this.farmId,
    required this.fields,
    required this.memberId,
    required this.treatments,
    required this.startDate,
    this.completedDate,
    this.documentOnSewageSludge,
  });

  static String _d(DateTime d) => d.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() => {
        'farmId': farmId,
        'fields': fields,
        'memberId': memberId,
        'treatments': treatments.map((t) => t.toJson()).toList(),
        'startDate': _d(startDate),
        if (completedDate != null) 'completedDate': _d(completedDate!),
        if (documentOnSewageSludge != null)
          'documentOnSewageSludge': documentOnSewageSludge,
      };
}
