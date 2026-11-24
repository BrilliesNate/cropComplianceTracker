// IPW (Integrated Production of Wine) - Cellar Audit Index
// Auto-generated from IPW_Cellar_Audit_Index_WIETA_Format.docx
// Seeds all IPW categories + document types tagged packageId: 'ipw'.
//
// Trigger once from the admin Data Fix Utility screen.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> setupIPWData(BuildContext context) async {
  final firestore = FirebaseFirestore.instance;

  // Guard: don't double-seed.
  final existing = await firestore
      .collection('categories')
      .where('packageId', isEqualTo: 'ipw')
      .limit(1)
      .get();
  if (existing.docs.isNotEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('IPW package already exists - skipping.')));
    }
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Setting up IPW categories...'),
      ]),
    ),
  );

  try {
    // ========================================================
    // 1. Training
    // ========================================================
    final cat1Ref = await firestore.collection('categories').add({
      'name': '1. Training',
      'description': '',
      'order': 1,
      'packageId': 'ipw',
    });
    final cat1DocTypes = [
      {
        'name': 'IPW Training Certificate – Cellar',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat1DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat1Ref.id});
    }

    // ========================================================
    // 2. Zoning, Registration & Incoming Water Analysis
    // ========================================================
    final cat2Ref = await firestore.collection('categories').add({
      'name': '2. Zoning, Registration & Incoming Water Analysis',
      'description': '',
      'order': 2,
      'packageId': 'ipw',
    });
    final cat2DocTypes = [
      {
        'name': 'Cellar Zoning Certificate (Sonering Sertifikaat) – confirms Agricultural-Industrial land use',
        'allowMultipleDocuments': false,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cellar Map / Google Earth Image – showing buildings, water sources, drainage, irrigation areas',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water Registration – incoming water permit / registration with DWS',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Wastewater Disposal Permit / Registration',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Stormwater / Runoff Permit / Registration',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Suitable Premises Certificate (Geskiktheid Sertifikaat) – confirms zoning, water registration, sewage, drainage records',
        'allowMultipleDocuments': false,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Drinking Water Analysis – chemical & microbiological, SANAS accredited lab, within 12 months of audit',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Incoming Process Water Analysis – all water used in the cellar',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Sewage Removal Record – documentation of legal disposal; municipal invoices where applicable',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat2DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat2Ref.id});
    }

    // ========================================================
    // 3. Quality of Incoming Grapes
    // ========================================================
    final cat3Ref = await firestore.collection('categories').add({
      'name': '3. Quality of Incoming Grapes',
      'description': '',
      'order': 3,
      'packageId': 'ipw',
    });
    final cat3DocTypes = [
      {
        'name': 'Grape Intake Records – date, mass, origin, cultivar, rot %, temperature per load received',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Procedure: Quality & Temperature of Incoming Grapes',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat3DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat3Ref.id});
    }

    // ========================================================
    // 4. Carbon Dioxide / CO₂ Footprint
    // ========================================================
    final cat4Ref = await firestore.collection('categories').add({
      'name': '4. Carbon Dioxide / CO₂ Footprint',
      'description': '',
      'order': 4,
      'packageId': 'ipw',
    });
    final cat4DocTypes = [
      {
        'name': 'Carbon Footprint / Energy Records – monthly electricity, diesel, petrol, gas usage (minimum 2 years)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'CO₂ Footprint Calculation – CCC Calculator (www.climatefruitandwine.co.za), graded A–C',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Energy Management Plan',
        'allowMultipleDocuments': false,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat4DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat4Ref.id});
    }

    // ========================================================
    // 5. Cellar Equipment Maintenance
    // ========================================================
    final cat5Ref = await firestore.collection('categories').add({
      'name': '5. Cellar Equipment Maintenance',
      'description': '',
      'order': 5,
      'packageId': 'ipw',
    });
    final cat5DocTypes = [
      {
        'name': 'Tank Maintenance Record – inert lining / stainless steel; all cellar tanks & equipment (every 5 years)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cellar Equipment & Infrastructure Inspection Record',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Food-Grade Lubricants Record – certificates confirming food-safe lubricants used in the cellar',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Pest Control Records – trap placement map, floor plan, MSDS of products used, service invoices',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Equipment Calibration Records – scales, meters, measuring devices',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat5DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat5Ref.id});
    }

    // ========================================================
    // 6. SO₂ Levels
    // ========================================================
    final cat6Ref = await firestore.collection('categories').add({
      'name': '6. SO₂ Levels',
      'description': '',
      'order': 6,
      'packageId': 'ipw',
    });
    final cat6DocTypes = [
      {
        'name': 'SO₂ Usage Report – weighted average total SO₂ of bottled certified wines in the 12 months preceding audit; official lab analysis (WSR2A & WSR4A)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat6DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat6Ref.id});
    }

    // ========================================================
    // 7. Winemaking Practices
    // ========================================================
    final cat7Ref = await firestore.collection('categories').add({
      'name': '7. Winemaking Practices',
      'description': '',
      'order': 7,
      'packageId': 'ipw',
    });
    final cat7DocTypes = [
      {
        'name': 'GMO Records – updated non-GMO certificates for all applicable products (yeasts, enzymes, bacteria, etc.)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Wine Additives Record – Annexure 5B evaluation of all additives used',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Wine Filtration Record – filtration types used during winemaking (e.g. pre-fermentation, post-fermentation, bottling)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Traceability Record – five examples including four additive records (two during & two post-harvest) and one wine transfer',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Traceability Procedure – Cellar',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'MSDS Records – Material Safety Data Sheets for all products used in the cellar',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'COC / COA\'s – Certificates of Conformity / Analysis for all incoming products',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Wine Additives Records (Wynbyvoegmiddels) – for traceability purposes',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cleaning Agents Records – for traceability purposes',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat7DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat7Ref.id});
    }

    // ========================================================
    // 8. Refrigeration
    // ========================================================
    final cat8Ref = await firestore.collection('categories').add({
      'name': '8. Refrigeration',
      'description': '',
      'order': 8,
      'packageId': 'ipw',
    });
    final cat8DocTypes = [
      {
        'name': 'Refrigeration Record – summary of all refrigeration units on the property and the refrigerant gas type used (classified per Annexure 5C)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat8DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat8Ref.id});
    }

    // ========================================================
    // 9. Wastewater Management
    // ========================================================
    final cat9Ref = await firestore.collection('categories').add({
      'name': '9. Wastewater Management',
      'description': '',
      'order': 9,
      'packageId': 'ipw',
    });
    final cat9DocTypes = [
      {
        'name': 'Cellar Wastewater Management Plan – scientific study (Water Quality Management Report) demonstrating beneficial end-use of wastewater',
        'allowMultipleDocuments': false,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cellar Wastewater Volume Record – weekly incoming & outgoing water volumes (upload monthly – last 4 weeks)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cellar Wastewater Treatment Record',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cellar Wastewater Analysis – monthly EC, pH, COD, NAV, K, faecal coliforms (SANAS accredited lab)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cellar Wastewater Storage Plan – programme diagram showing handling, storage capacity, end-use of wastewater',
        'allowMultipleDocuments': false,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Wastewater Disposal Registration / Permit – DWS General Authorisation or licence; volume registered',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat9DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat9Ref.id});
    }

    // ========================================================
    // 10. Sanitisers & Cleaning Agents
    // ========================================================
    final cat10Ref = await firestore.collection('categories').add({
      'name': '10. Sanitisers & Cleaning Agents',
      'description': '',
      'order': 10,
      'packageId': 'ipw',
    });
    final cat10DocTypes = [
      {
        'name': 'Cellar Cleaning & Sanitising Procedure – handling and dispensing of chemicals; Annexure 5H evaluation',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'MSDS Records – Material Safety Data Sheets for all cleaning and sanitising products',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cleaning Agents Records – list of all products used, categorised per Annexure 5H (Good / Average / Poor)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat10DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat10Ref.id});
    }

    // ========================================================
    // 11. Solid Waste Management
    // ========================================================
    final cat11Ref = await firestore.collection('categories').add({
      'name': '11. Solid Waste Management',
      'description': '',
      'order': 11,
      'packageId': 'ipw',
    });
    final cat11DocTypes = [
      {
        'name': 'Solid Waste Disposal Record – removal records, 12-month summary of volumes removed, municipal invoices or contractor agreement & permit for non-recyclable waste transport',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat11DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat11Ref.id});
    }

    // ========================================================
    // 12. Environmental Noise
    // ========================================================
    final cat12Ref = await firestore.collection('categories').add({
      'name': '12. Environmental Noise',
      'description': '',
      'order': 12,
      'packageId': 'ipw',
    });
    final cat12DocTypes = [
      {
        'name': 'Cellar Noise Level Specification – environmental noise study in accordance with SANS 10103:2008 Ed. 6 (max 45 dBA at boundary)',
        'allowMultipleDocuments': false,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cellar Noise Management Plan – measures to restrict noisy equipment/vehicles to 07:00–20:00 if noise exceeds 45 dB outside the cellar',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat12DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat12Ref.id});
    }

    // ========================================================
    // 13. Packaging Material
    // ========================================================
    final cat13Ref = await firestore.collection('categories').add({
      'name': '13. Packaging Material',
      'description': '',
      'order': 13,
      'packageId': 'ipw',
    });
    final cat13DocTypes = [
      {
        'name': 'Packaging Material Record – summary from suppliers confirming material type for closures, capsules, labels, bottles, cartons and bottle trays; indicates if biodegradable, recyclable or made from recycled material',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat13DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat13Ref.id});
    }

    // ========================================================
    // 14. Glass Breakage
    // ========================================================
    final cat14Ref = await firestore.collection('categories').add({
      'name': '14. Glass Breakage',
      'description': '',
      'order': 14,
      'packageId': 'ipw',
    });
    final cat14DocTypes = [
      {
        'name': 'Glass Breakage Procedure – 12-step procedure for isolating, cleaning and clearing glass on the bottling line',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Glass Breakage Record – record of breakages (or confirmation of nil breakages); cellar policy on protective earwear and jewellery',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];
    for (final dt in cat14DocTypes) {
      await firestore.collection('documentTypes').add({...dt, 'categoryId': cat14Ref.id});
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('IPW package created successfully'),
          backgroundColor: Colors.green));
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error seeding IPW: $e'),
          backgroundColor: Colors.red));
    }
  }
}
