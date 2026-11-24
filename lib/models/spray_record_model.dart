import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

enum SprayRecordType { spray, fertilizer }

extension SprayRecordTypeExt on SprayRecordType {
  String get value => this == SprayRecordType.spray ? 'spray' : 'fertilizer';
  String get label => this == SprayRecordType.spray
      ? LocaleProvider.instance.l10n.srTypeSpray
      : LocaleProvider.instance.l10n.srTypeFertilizer;

  static SprayRecordType fromString(String? s) =>
      s == 'fertilizer' ? SprayRecordType.fertilizer : SprayRecordType.spray;
}

class SprayRecord {
  final String id;
  final String companyId;
  final SprayRecordType type;

  // What / when
  final DateTime applicationDate;
  final String productName;
  final String? activeIngredient;
  final String? registrationNumber;
  final String targetPestOrCrop; // pest for spray, crop for fertilizer
  final double rate;
  final String unit; // e.g. L/ha, kg/ha, mL/100L
  final double? totalAmountUsed;

  // Where
  final List<String> fieldNames;
  final List<int> farmableFieldIds; // Farmable field IDs (empty if no Farmable)

  // Who / how
  final String operatorName;
  final String? equipment;

  // Safety / compliance
  final int? preHarvestIntervalDays;  // PHI
  final int? reEntryIntervalDays;     // REI
  final String? weatherConditions;

  // Extra
  final String? notes;

  // Sync state
  final bool farmableSynced;
  final int? farmableJobId;

  final DateTime createdAt;
  final DateTime updatedAt;

  SprayRecord({
    required this.id,
    required this.companyId,
    required this.type,
    required this.applicationDate,
    required this.productName,
    this.activeIngredient,
    this.registrationNumber,
    required this.targetPestOrCrop,
    required this.rate,
    required this.unit,
    this.totalAmountUsed,
    required this.fieldNames,
    this.farmableFieldIds = const [],
    required this.operatorName,
    this.equipment,
    this.preHarvestIntervalDays,
    this.reEntryIntervalDays,
    this.weatherConditions,
    this.notes,
    this.farmableSynced = false,
    this.farmableJobId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'type': type.value,
        'applicationDate': Timestamp.fromDate(applicationDate),
        'productName': productName,
        if (activeIngredient != null) 'activeIngredient': activeIngredient,
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        'targetPestOrCrop': targetPestOrCrop,
        'rate': rate,
        'unit': unit,
        if (totalAmountUsed != null) 'totalAmountUsed': totalAmountUsed,
        'fieldNames': fieldNames,
        'farmableFieldIds': farmableFieldIds,
        'operatorName': operatorName,
        if (equipment != null) 'equipment': equipment,
        if (preHarvestIntervalDays != null) 'preHarvestIntervalDays': preHarvestIntervalDays,
        if (reEntryIntervalDays != null) 'reEntryIntervalDays': reEntryIntervalDays,
        if (weatherConditions != null) 'weatherConditions': weatherConditions,
        if (notes != null) 'notes': notes,
        'farmableSynced': farmableSynced,
        if (farmableJobId != null) 'farmableJobId': farmableJobId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory SprayRecord.fromMap(Map<String, dynamic> map, String id) => SprayRecord(
        id: id,
        companyId: map['companyId'] ?? '',
        type: SprayRecordTypeExt.fromString(map['type']),
        applicationDate:
            (map['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        productName: map['productName'] ?? '',
        activeIngredient: map['activeIngredient'],
        registrationNumber: map['registrationNumber'],
        targetPestOrCrop: map['targetPestOrCrop'] ?? '',
        rate: (map['rate'] ?? 0.0).toDouble(),
        unit: map['unit'] ?? 'L/ha',
        totalAmountUsed: (map['totalAmountUsed'] as num?)?.toDouble(),
        fieldNames: List<String>.from(map['fieldNames'] ?? []),
        farmableFieldIds:
            List<int>.from((map['farmableFieldIds'] ?? []).map((e) => e as int)),
        operatorName: map['operatorName'] ?? '',
        equipment: map['equipment'],
        preHarvestIntervalDays: map['preHarvestIntervalDays'] as int?,
        reEntryIntervalDays: map['reEntryIntervalDays'] as int?,
        weatherConditions: map['weatherConditions'],
        notes: map['notes'],
        farmableSynced: map['farmableSynced'] ?? false,
        farmableJobId: map['farmableJobId'] as int?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  SprayRecord copyWith({
    String? productName,
    String? activeIngredient,
    String? registrationNumber,
    String? targetPestOrCrop,
    double? rate,
    String? unit,
    double? totalAmountUsed,
    List<String>? fieldNames,
    List<int>? farmableFieldIds,
    String? operatorName,
    String? equipment,
    int? preHarvestIntervalDays,
    int? reEntryIntervalDays,
    String? weatherConditions,
    String? notes,
    bool? farmableSynced,
    int? farmableJobId,
    DateTime? applicationDate,
  }) =>
      SprayRecord(
        id: id,
        companyId: companyId,
        type: type,
        applicationDate: applicationDate ?? this.applicationDate,
        productName: productName ?? this.productName,
        activeIngredient: activeIngredient ?? this.activeIngredient,
        registrationNumber: registrationNumber ?? this.registrationNumber,
        targetPestOrCrop: targetPestOrCrop ?? this.targetPestOrCrop,
        rate: rate ?? this.rate,
        unit: unit ?? this.unit,
        totalAmountUsed: totalAmountUsed ?? this.totalAmountUsed,
        fieldNames: fieldNames ?? this.fieldNames,
        farmableFieldIds: farmableFieldIds ?? this.farmableFieldIds,
        operatorName: operatorName ?? this.operatorName,
        equipment: equipment ?? this.equipment,
        preHarvestIntervalDays: preHarvestIntervalDays ?? this.preHarvestIntervalDays,
        reEntryIntervalDays: reEntryIntervalDays ?? this.reEntryIntervalDays,
        weatherConditions: weatherConditions ?? this.weatherConditions,
        notes: notes ?? this.notes,
        farmableSynced: farmableSynced ?? this.farmableSynced,
        farmableJobId: farmableJobId ?? this.farmableJobId,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

/// Common application rate units for spray/fertilizer records.
const kSprayUnits = [
  'L/ha', 'mL/ha', 'kg/ha', 'g/ha',
  'mL/100L water', 'g/100L water', // l10n-ignore: units (same in Afrikaans)
  'L/1000L water', 'kg/1000L water', // l10n-ignore: units (same in Afrikaans)
];
