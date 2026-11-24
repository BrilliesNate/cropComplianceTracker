// SIZA Environmental Audit Index
// Source: "SIZA Environmental Audit Index.docx" (Nov 2026), generated from the
// document so every name and flag is copied exactly.
// Seeds the SIZA Environmental categories + document types tagged packageId:
// 'siza_environmental'. Trigger once from the admin Data Fix Utility screen.
//
// Each item's flags, as listed in the document, are encoded as letters:
//   M  more than one document allowed
//   E  has an expiry date
//   N  can be marked Not Applicable
//   S  specification needed (Specification box becomes required)
//   R  "{add reviewed date}" — uploader enters the date it was last reviewed
// Every item is uploadable and none needs a signature.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Package id stored on categories and companies.
const String sizaEnvironmentalPackageId = 'siza_environmental';

class _EnvItem {
  final String name;
  final String flags;
  const _EnvItem(this.name, this.flags);
}

class _EnvSection {
  final String name;
  final List<_EnvItem> items;
  const _EnvSection(this.name, this.items);
}

/// 5 sections, 92 document types.
const List<_EnvSection> sizaEnvironmentalSections = [
  _EnvSection('1. Management Systems', [
    _EnvItem('Environmental management policy', 'MESR'),
    _EnvItem('Senior management representative appointment (written)', 'MS'),
    _EnvItem(
        'Evidence of policy communication to staff: induction training records',
        'MS'),
    _EnvItem('Annual environmental awareness training records', 'MES'),
    _EnvItem(
        'Policy shared via compliance platforms (e.g. MySIZA, Sedex)', 'MS'),
    _EnvItem('Environmental Management Plan (EMP)', 'MESR'),
    _EnvItem('Environmental Risk Assessment (ERA)', 'MS'),
    _EnvItem(
        'Annual senior management sign-off / review record for ERA', 'MES'),
    _EnvItem('Soil measurement and monitoring records (ERA)', 'MS'),
    _EnvItem('Water measurement and monitoring records (ERA)', 'MS'),
    _EnvItem('Energy, materials and waste monitoring records (ERA)', 'MS'),
    _EnvItem('Biodiversity and ecosystems monitoring records (ERA)', 'MES'),
    _EnvItem(
        'Legal register / process for staying current with environmental legislation',
        'MS'),
    _EnvItem(
        'Environmental permits and authorisations – all applicable', 'MES'),
    _EnvItem('IAP control plan', 'MS'),
    _EnvItem('GMO compliance documentation (if applicable)', 'MNS'),
    _EnvItem(
        'Biodiversity conservation / stewardship agreement (if applicable)',
        'MNS'),
    _EnvItem('Supplier environmental audit programme: packhouses only', 'MNS'),
  ]),
  _EnvSection('2. Environmental Principle 1 – Minimise Negative Impacts', [
    _EnvItem(
        'Site map (production units, roads, infrastructure, ecosystems, conservation areas, boundaries)',
        'MS'),
    _EnvItem(
        'Evidence of no disturbance to biodiversity priority areas in past 10 years',
        'MS'),
    _EnvItem(
        'EIA/BA authorisations for any land transformation or disturbance of natural vegetation',
        'MENS'),
    _EnvItem('Restoration and conservation plan for any impacted natural areas',
        'MNS'),
    _EnvItem(
        'Planting material records – source, quality, buyer compliance', 'MS'),
    _EnvItem(
        'Agrochemical product selection and application records (PPPs per infestation level and growth stage)',
        'MS'),
    _EnvItem(
        'Technical advisor qualifications and CPD training records (min. 8 hours/year)',
        'MES'),
    _EnvItem(
        'SANS 10206 compliance evidence (pesticide handling, storage, disposal)',
        'MS'),
    _EnvItem(
        'Hazardous substance handling and emergency procedures (displayed in workplace)',
        'MS'),
    _EnvItem('Prohibited chemicals list and compliance evidence', 'MS'),
    _EnvItem('Chemical handling training records', 'MS'),
    _EnvItem('Bunded fuel storage / chemical storage inspection records', 'MS'),
    _EnvItem('Chemical filling and mixing point documentation', 'MS'),
    _EnvItem('Buffer zone records adjacent to all water sources', 'MS'),
    _EnvItem(
        'Water quality test results – abstraction and disposal points (SANAS-accredited lab)',
        'MES'),
    _EnvItem('Water management plan (updated annually, zero-pollution target)',
        'MESR'),
    _EnvItem('Pollution management/containment procedure', 'MS'),
    _EnvItem('Soil and crop/leaf sample results (SANAS-accredited lab)', 'MES'),
    _EnvItem(
        'Soil management map (soil units, high-risk areas: erosion, compaction, salinisation)',
        'MS'),
    _EnvItem('Soil management policy and plan', 'MS'),
    _EnvItem('Erosion and compaction prevention records', 'MS'),
    _EnvItem('IAP species list and site knowledge evidence', 'MS'),
    _EnvItem(
        'IAP clearing and monitoring plan (prioritising riparian and mountain catchment areas)',
        'MS'),
    _EnvItem('IAP clearing staff training records', 'MS'),
  ]),
  _EnvSection('3. Environmental Principle 2 – Measured & Efficient Use', [
    _EnvItem(
        'DWS water registration/licence papers for all water sources', 'MES'),
    _EnvItem(
        'Water meter records – consumption vs. allocation (monthly or annual)',
        'MES'),
    _EnvItem('Water Use Efficiency (WUE) calculations per crop (L/kg)', 'MS'),
    _EnvItem('Annual WUE targets and year-on-year comparison', 'MES'),
    _EnvItem('Water conservation practices and technology records', 'MS'),
    _EnvItem(
        'Grey water / rainwater harvesting records (if applicable)', 'MNS'),
    _EnvItem(
        'Energy use records – electricity (kWh), diesel/petrol (litres), LPG (litres)',
        'MES'),
    _EnvItem(
        'Annual energy use report (most energy-intensive activities; renewable vs. non-renewable breakdown)',
        'MES'),
    _EnvItem('Energy efficiency targets and year-on-year comparison', 'MES'),
    _EnvItem('Baseline carbon footprint report', 'MS'),
    _EnvItem(
        'Fertiliser and agrochemical inventory (in storage and in application)',
        'MES'),
    _EnvItem('Fertiliser and agrochemical application records', 'MS'),
    _EnvItem('Application equipment calibration and maintenance logs', 'MES'),
    _EnvItem(
        'Holistic fertiliser programme (annually reviewed, based on soil and leaf analysis)',
        'MESR'),
    _EnvItem('Integrated Pest Management (IPM) plan per pest', 'MS'),
    _EnvItem('Pest monitoring and scouting records', 'MS'),
    _EnvItem('Pre-harvest interval (PHI) procedure', 'MS'),
    _EnvItem(
        'Waste stream register (all waste types identified and quantified)',
        'MS'),
    _EnvItem('Waste management plan (generation, storage, transport, disposal)',
        'MESR'),
    _EnvItem(
        'Recycling records and evidence (bins, collection, composting)', 'MS'),
    _EnvItem('Waste storage facility compliance records', 'MS'),
    _EnvItem('Year-on-year waste intensity records (kg waste per kg product)',
        'MES'),
    _EnvItem('Drainage scheme map for fields and farm buildings', 'MS'),
  ]),
  _EnvSection('4. Environmental Principle 3 – Shifting to Alternatives', [
    _EnvItem(
        'Energy management plan with renewable energy targets and timelines',
        'MS'),
    _EnvItem(
        'Percentage of total energy from renewable sources (or investment evidence)',
        'MS'),
    _EnvItem(
        'Agrochemical reduction plan – shifting to sustainable alternatives',
        'MS'),
    _EnvItem(
        'Annual synthetic pesticide report (active ingredients kg/ha per crop)',
        'MES'),
    _EnvItem(
        'Year-on-year fertiliser records showing decline in synthetic product use',
        'MES'),
    _EnvItem(
        'Soil health improvement practices integrated into soil management plan',
        'MS'),
    _EnvItem(
        'Waste records with quantities going to landfill vs. diverted', 'MES'),
    _EnvItem(
        'Zero-waste targets (updated annually) and evidence of targets being met',
        'MESR'),
    _EnvItem(
        'Extended Producer Responsibility (EPR) / PRO compliance from packaging suppliers',
        'MS'),
    _EnvItem(
        '3-year GHG / carbon footprint assessment reports showing declining trend',
        'MES'),
    _EnvItem(
        'Emission reduction plan with zero-emission targets (reviewed annually)',
        'MESR'),
    _EnvItem('Carbon offset certificates (if applicable)', 'MENS'),
  ]),
  _EnvSection(
      '5. Environmental Principle 4 – Restored & Conserved Ecosystem Services',
      [
        _EnvItem(
            'Multi-year soil carbon (SOC) test results showing increasing trend',
            'MES'),
        _EnvItem(
            'Soil health monitoring records (pH, texture, SOC, aggregate stability, N/P/K, earthworm counts, etc.)',
            'MS'),
        _EnvItem('Catchment-level water risk assessment', 'MS'),
        _EnvItem(
            'WUA / CMA membership records and participation evidence', 'MS'),
        _EnvItem('Biodiversity assessment report (specialist survey)', 'MES'),
        _EnvItem('Biodiversity management plan', 'MS'),
        _EnvItem(
            'Biodiversity map (CBAs, ESAs, SWSAs, priority restoration areas, water features)',
            'MS'),
        _EnvItem(
            'Policy commitment to protect all pristine natural areas from production activities',
            'MS'),
        _EnvItem(
            'Evidence of no production activities in protected/high conservation value areas',
            'MS'),
        _EnvItem(
            'Animal use and grazing management plan (if animals/livestock on farm)',
            'MNS'),
        _EnvItem(
            'Animal health plan (vet checks, vaccinations, treatment records)',
            'MNS'),
        _EnvItem(
            'Animal emergency plan (natural disasters and disease outbreaks)',
            'MNS'),
        _EnvItem('Staff training records – safe animal handling and transport',
            'MNS'),
        _EnvItem('Animal nutrition and feeding plan', 'MNS'),
        _EnvItem('Grazing plan (to minimise bought-in feed)', 'MNS'),
      ]),
];

/// Firestore document-type fields for one item.
Map<String, dynamic> sizaEnvironmentalTypeFields(String name, String flags) => {
      'name': name,
      'allowMultipleDocuments': flags.contains('M'),
      'isUploadable': true,
      'hasExpiryDate': flags.contains('E'),
      'hasNotApplicableOption': flags.contains('N'),
      'requiresSignature': false,
      'signatureCount': 0,
      'hasFormTemplate': false,
      'requiresSpecification': flags.contains('S'),
      'hasReviewedDate': flags.contains('R'),
    };

/// Seeds every SIZA Environmental category and document type. Safe to tap
/// twice: it skips when SIZA Environmental categories already exist.
Future<void> setupSizaEnvironmentalData(BuildContext context) async {
  final firestore = FirebaseFirestore.instance;

  final existing = await firestore
      .collection('categories')
      .where('packageId', isEqualTo: sizaEnvironmentalPackageId)
      .limit(1)
      .get();
  if (existing.docs.isNotEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('SIZA Environmental package already exists — skipping.')));
    }
    return;
  }
  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Setting up SIZA Environmental categories…'),
      ]),
    ),
  );

  var types = 0;
  try {
    for (var i = 0; i < sizaEnvironmentalSections.length; i++) {
      final section = sizaEnvironmentalSections[i];
      final catRef = firestore.collection('categories').doc();
      final batch = firestore.batch();
      batch.set(catRef, {
        'name': section.name,
        'description': '',
        'order': i + 1,
        'packageId': sizaEnvironmentalPackageId,
      });
      for (final item in section.items) {
        batch.set(firestore.collection('documentTypes').doc(), {
          ...sizaEnvironmentalTypeFields(item.name, item.flags),
          'categoryId': catRef.id,
        });
        types++;
      }
      await batch.commit();
    }
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('SIZA Environmental set up: '
            '${sizaEnvironmentalSections.length} categories, $types document '
            'types. Turn it on per company in Company Management.'),
      ));
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SIZA Environmental setup failed: $e')));
    }
  }
}
