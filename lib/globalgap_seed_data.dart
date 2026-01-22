// GlobalG.A.P. Audit Index (Version 6) - Database Seed Script
// Run this function to populate the database with all categories and document types

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> setupGlobalGAPData(BuildContext context) async {
  final firestore = FirebaseFirestore.instance;

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Setting up GlobalG.A.P. categories...'),
        ],
      ),
    ),
  );

  try {
    // ============================================================
    // 1. INTERNAL DOCUMENTATION
    // ============================================================
    final cat1Ref = await firestore.collection('categories').add({
      'name': '1. Internal Documentation',
      'description': 'Document and record management, auditing records, self-assessment, and corrective actions',
      'order': 1,
    });

    final cat1DocTypes = [
      {
        'name': 'Document control procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'All required records dating back at least 2 years',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Completed self-assessment/internal audit documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Comments on all non-applicable or non-compliant items',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Documented corrective actions for issues identified (Major, minor, recommendation)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Evidence of implementation of corrective actions',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
    ];

    for (var docType in cat1DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat1Ref.id,
      });
    }

    // ============================================================
    // 2. CONTINUOUS IMPROVEMENT PLAN
    // ============================================================
    final cat2Ref = await firestore.collection('categories').add({
      'name': '2. Continuous Improvement Plan',
      'description': 'Documented continuous improvement planning',
      'order': 2,
    });

    final cat2DocTypes = [
      {
        'name': 'Documented continuous improvement plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
    ];

    for (var docType in cat2DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat2Ref.id,
      });
    }

    // ============================================================
    // 3. RESOURCE MANAGEMENT AND TRAINING
    // ============================================================
    final cat3Ref = await firestore.collection('categories').add({
      'name': '3. Resource Management and Training',
      'description': 'Competence, training, and food safety training requirements',
      'order': 3,
    });

    final cat3DocTypes = [
      {
        'name': 'Organogram',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Training schedule',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': "Chemical Advisor's Croplife Membership certificate",
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': "Fertilizer Advisor's Qualification",
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Food safety and hygiene training records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of refresher training',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Training materials on food safety topics',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat3DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat3Ref.id,
      });
    }

    // ============================================================
    // 4. OUTSOURCED ACTIVITIES (SUBCONTRACTORS)
    // ============================================================
    final cat4Ref = await firestore.collection('categories').add({
      'name': '4. Outsourced Activities (Subcontractors)',
      'description': 'Control and monitoring of all outsourced activities',
      'order': 4,
    });

    final cat4DocTypes = [
      {
        'name': 'List of all subcontractors',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Subcontractor agreements/contracts',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Monitoring records of subcontractor performance',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat4DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat4Ref.id,
      });
    }

    // ============================================================
    // 5. SPECIFICATIONS, SUPPLIERS, AND STOCK MANAGEMENT
    // ============================================================
    final cat5Ref = await firestore.collection('categories').add({
      'name': '5. Specifications, Suppliers, and Stock Management',
      'description': 'Material specifications, supplier approval, and inventory management',
      'order': 5,
    });

    final cat5DocTypes = [
      {
        'name': 'Product specifications for all raw materials',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Packaging material specifications',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Supplier approval procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Approved supplier list',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': true,
      },
      {
        'name': 'Inventory records for chemicals and fertilizers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': true,
      },
      {
        'name': 'Stock rotation system documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat5DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat5Ref.id,
      });
    }

    // ============================================================
    // 6. TRACEABILITY
    // ============================================================
    final cat6Ref = await firestore.collection('categories').add({
      'name': '6. Traceability',
      'description': 'Traceability system and product identification',
      'order': 6,
    });

    final cat6DocTypes = [
      {
        'name': 'Traceability procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Mock Recall documentation for each variety',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Product identification records (bin ticket with GGN)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat6DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat6Ref.id,
      });
    }

    // ============================================================
    // 7. PARALLEL OWNERSHIP, TRACEABILITY, AND SEGREGATION
    // ============================================================
    final cat7Ref = await firestore.collection('categories').add({
      'name': '7. Parallel Ownership, Traceability, and Segregation',
      'description': 'Product segregation and identification systems (if applicable)',
      'order': 7,
    });

    final cat7DocTypes = [
      {
        'name': 'Procedure for handling certified and non-certified products',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Identification system documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of product separation measures',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat7DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat7Ref.id,
      });
    }

    // ============================================================
    // 8. MASS BALANCE
    // ============================================================
    final cat8Ref = await firestore.collection('categories').add({
      'name': '8. Mass Balance',
      'description': 'Mass balance reconciliation records',
      'order': 8,
    });

    final cat8DocTypes = [
      {
        'name': 'Sales records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Mass balance calculation records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat8DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat8Ref.id,
      });
    }

    // ============================================================
    // 9. RECALL AND WITHDRAWAL
    // ============================================================
    final cat9Ref = await firestore.collection('categories').add({
      'name': '9. Recall and Withdrawal',
      'description': 'Product recall and withdrawal procedures',
      'order': 9,
    });

    final cat9DocTypes = [
      {
        'name': 'Product recall and withdrawal procedure with contact list',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Actual recall/complaint records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat9DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat9Ref.id,
      });
    }

    // ============================================================
    // 10. COMPLAINTS
    // ============================================================
    final cat10Ref = await firestore.collection('categories').add({
      'name': '10. Complaints',
      'description': 'Complaint handling and grievance mechanism',
      'order': 10,
    });

    final cat10DocTypes = [
      {
        'name': 'Complaint handling procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Complaint records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of corrective actions for complaints',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Grievance Mechanism training records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Grievance Procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat10DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat10Ref.id,
      });
    }

    // ============================================================
    // 11. NON-CONFORMING PRODUCTS
    // ============================================================
    final cat11Ref = await firestore.collection('categories').add({
      'name': '11. Non-Conforming Products',
      'description': 'Procedures for identifying and handling non-conforming products',
      'order': 11,
    });

    final cat11DocTypes = [
      {
        'name': 'Non-conforming product procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Non-conforming product records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Disposition records for non-conforming products',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat11DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat11Ref.id,
      });
    }

    // ============================================================
    // 12. LABORATORY TESTING
    // ============================================================
    final cat12Ref = await firestore.collection('categories').add({
      'name': '12. Laboratory Testing',
      'description': 'Laboratory selection and testing methods',
      'order': 12,
    });

    final cat12DocTypes = [
      {
        'name': 'List of approved laboratories',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Laboratory accreditation certificates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat12DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat12Ref.id,
      });
    }

    // ============================================================
    // 13. EQUIPMENT AND DEVICES
    // ============================================================
    final cat13Ref = await firestore.collection('categories').add({
      'name': '13. Equipment and Devices',
      'description': 'Equipment calibration, verification, storage, and maintenance',
      'order': 13,
    });

    final cat13DocTypes = [
      {
        'name': 'Equipment calibration procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Calibration records for spraypumps',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Calibration records for chemical scales',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Verification records for chemical measuring instruments',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': true,
      },
      {
        'name': 'Equipment maintenance records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Inspection records (Equipment Storage)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Inspection records of vehicles including cleaning',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Service records of all vehicles applicable to production',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat13DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat13Ref.id,
      });
    }

    // ============================================================
    // 14. FOOD SAFETY POLICY DECLARATION
    // ============================================================
    final cat14Ref = await firestore.collection('categories').add({
      'name': '14. Food Safety Policy Declaration',
      'description': 'Management commitment to food safety',
      'order': 14,
    });

    final cat14DocTypes = [
      {
        'name': 'Signed food safety policy declaration',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat14DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat14Ref.id,
      });
    }

    // ============================================================
    // 15. FOOD DEFENSE
    // ============================================================
    final cat15Ref = await firestore.collection('categories').add({
      'name': '15. Food Defense',
      'description': 'Food defense vulnerabilities assessment and planning',
      'order': 15,
    });

    final cat15DocTypes = [
      {
        'name': 'Food defense risk assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Food defense management plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat15DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat15Ref.id,
      });
    }

    // ============================================================
    // 16. FOOD FRAUD
    // ============================================================
    final cat16Ref = await firestore.collection('categories').add({
      'name': '16. Food Fraud',
      'description': 'Food fraud vulnerability assessment and mitigation',
      'order': 16,
    });

    final cat16DocTypes = [
      {
        'name': 'Food fraud risk assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Food fraud management plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat16DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat16Ref.id,
      });
    }

    // ============================================================
    // 17. LOGO USE
    // ============================================================
    final cat17Ref = await firestore.collection('categories').add({
      'name': '17. Logo Use',
      'description': 'GLOBALG.A.P. logo and GGN usage',
      'order': 17,
    });

    final cat17DocTypes = [
      {
        'name': 'Evidence of correct logo usage',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'GLOBALG.A.P. logo use procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'GGN Agreement/Service Level Agreement with packhouse',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat17DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat17Ref.id,
      });
    }

    // ============================================================
    // 18. GLOBALG.A.P. STATUS
    // ============================================================
    final cat18Ref = await firestore.collection('categories').add({
      'name': '18. GLOBALG.A.P. Status',
      'description': 'Transaction certificates for certified products',
      'order': 18,
    });

    final cat18DocTypes = [
      {
        'name': 'Transaction certificates with GGN if applicable',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat18DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat18Ref.id,
      });
    }

    // ============================================================
    // 19. HYGIENE
    // ============================================================
    final cat19Ref = await firestore.collection('categories').add({
      'name': '19. Hygiene',
      'description': 'Hygiene risk assessment, personal hygiene, training, and facilities',
      'order': 19,
    });

    final cat19DocTypes = [
      {
        'name': 'Hygiene risk assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Hygiene policy',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Hygiene procedure and instructions',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Food safety and hygiene training records (Hygiene)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of refresher training (Hygiene)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Training materials on food safety topics (Hygiene)',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Toilet and hand washing facilities inspection records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': true,
      },
      {
        'name': 'Animal Contamination Control Procedure',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Harvest and Production Container Inspection records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': true,
      },
    ];

    for (var docType in cat19DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat19Ref.id,
      });
    }

    // ============================================================
    // 20. WORKERS' HEALTH, SAFETY, AND WELFARE
    // ============================================================
    final cat20Ref = await firestore.collection('categories').add({
      'name': "20. Workers' Health, Safety, and Welfare",
      'description': 'Health and safety risk assessment, training, PPE, and welfare',
      'order': 20,
    });

    final cat20DocTypes = [
      {
        'name': 'Health and safety risk assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Health and safety procedures',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Accident and incident records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Accident and emergency procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Accident reporting procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'First aid kit inspection records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'PPE provision records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': true,
      },
      {
        'name': 'PPE wash records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Drinking water analysis',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Transport of workers rules and procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'PDP records for all drivers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat20DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat20Ref.id,
      });
    }

    // ============================================================
    // 21. SITE MANAGEMENT
    // ============================================================
    final cat21Ref = await firestore.collection('categories').add({
      'name': '21. Site Management',
      'description': 'Site assessment, management, water sources, and allergen management',
      'order': 21,
    });

    final cat21DocTypes = [
      {
        'name': 'Site risk assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Farming Good practices management plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Block record',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Maps of production areas',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of mitigation measures if risks identified',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Details on water sources used on the farm',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Map showing location of water sources',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water Use and Flow Management Plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Allergen Inventory List',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Allergen Risk Assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Allergen Segregation Procedures',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Allergen Labeling Procedure',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Allergen Training Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat21DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat21Ref.id,
      });
    }

    // ============================================================
    // 22. BIODIVERSITY AND HABITATS
    // ============================================================
    final cat22Ref = await firestore.collection('categories').add({
      'name': '22. Biodiversity and Habitats',
      'description': 'Biodiversity management, ecological enhancement, and ecosystem conservation',
      'order': 22,
    });

    final cat22DocTypes = [
      {
        'name': 'Biodiversity assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Biodiversity management plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of biodiversity enhancement activities',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Conservation area maps',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Plan for ecological enhancement of non-productive areas',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of ecological improvement activities',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Farm maps outlining buffer zones',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Management Plan for invasive species control',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Permits for removal of Invasive Species',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records for improved/enlarged natural areas',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Maps or Aerial Photos of biodiversity areas',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat22DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat22Ref.id,
      });
    }

    // ============================================================
    // 23. ENERGY EFFICIENCY
    // ============================================================
    final cat23Ref = await firestore.collection('categories').add({
      'name': '23. Energy Efficiency',
      'description': 'Energy use monitoring and efficiency measures',
      'order': 23,
    });

    final cat23DocTypes = [
      {
        'name': 'Energy consumption records (Diesel and Electricity)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Electricity consumption per Production Unit',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Diesel consumption per Production Unit',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Energy efficiency plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of energy-saving practices',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Equipment maintenance records for energy efficiency',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat23DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat23Ref.id,
      });
    }

    // ============================================================
    // 24. GREENHOUSE GASES AND CLIMATE CHANGE
    // ============================================================
    final cat24Ref = await firestore.collection('categories').add({
      'name': '24. Greenhouse Gases and Climate Change',
      'description': 'GHG emissions monitoring and reduction',
      'order': 24,
    });

    final cat24DocTypes = [
      {
        'name': 'GHG emissions assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Carbon reduction plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': true,
      },
      {
        'name': 'Records of carbon reduction practices',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Carbon footprint calculation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat24DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat24Ref.id,
      });
    }

    // ============================================================
    // 25. WASTE MANAGEMENT
    // ============================================================
    final cat25Ref = await firestore.collection('categories').add({
      'name': '25. Waste Management',
      'description': 'Waste reduction, management, equipment inspection, and plastic management',
      'order': 25,
    });

    final cat25DocTypes = [
      {
        'name': 'Waste management plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Waste separation procedure',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Waste disposal records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of waste reduction initiatives',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Forklift Loadtest',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Diesel Tank/Containment Inspections',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Evidence of Septic Tank Drainage',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Recycling or Reuse of Plastics records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat25DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat25Ref.id,
      });
    }

    // ============================================================
    // 26. PLANT PROPAGATION MATERIAL
    // ============================================================
    final cat26Ref = await firestore.collection('categories').add({
      'name': '26. Plant Propagation Material',
      'description': 'Plant material quality and health documentation',
      'order': 26,
    });

    final cat26DocTypes = [
      {
        'name': 'Nursery certificates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Seed/plant material purchase records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Plant registration/certification documents',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Nursery GMO Declaration',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Plant treatment records from nursery',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat26DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat26Ref.id,
      });
    }

    // ============================================================
    // 27. GENETICALLY MODIFIED ORGANISMS
    // ============================================================
    final cat27Ref = await firestore.collection('categories').add({
      'name': '27. Genetically Modified Organisms',
      'description': 'GMO use compliance and management',
      'order': 27,
    });

    final cat27DocTypes = [
      {
        'name': 'GMO status declaration',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Non-GMO certificates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'GMO testing records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Segregation procedures for GMO/non-GMO',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat27DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat27Ref.id,
      });
    }

    // ============================================================
    // 28. SOIL AND SUBSTRATE MANAGEMENT
    // ============================================================
    final cat28Ref = await firestore.collection('categories').add({
      'name': '28. Soil and Substrate Management',
      'description': 'Soil management, conservation, fumigation, and substrates',
      'order': 28,
    });

    final cat28DocTypes = [
      {
        'name': 'Soil management plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Soil Maps',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Soil analysis results',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Erosion control measures documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Crop rotation records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Justification for chemical fumigation if used',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of alternative fumigation methods considered',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Accreditation of fumigation company/applicator',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Fumigation application records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Substrate specifications',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Sterilization records for reused substrates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Recycling evidence for used substrates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of substrate use and disposal',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat28DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat28Ref.id,
      });
    }

    // ============================================================
    // 29. FERTILIZERS AND BIOSTIMULANTS
    // ============================================================
    final cat29Ref = await firestore.collection('categories').add({
      'name': '29. Fertilizers and Biostimulants',
      'description': 'Fertilizer application, storage, and organic fertilizer management',
      'order': 29,
    });

    final cat29DocTypes = [
      {
        'name': 'Fertilizer application records (dates, rates, methods, operators)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Fertilizer inventory records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Fertilizer storage procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Fertilizer storage area inspection records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Risk assessment for organic fertilizers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Application records for organic fertilizers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Microbial testing results for organic fertilizers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Compost management records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Declaration regarding human sewage',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Nutrient content documentation for all fertilizers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Soil/plant nutrient testing results',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat29DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat29Ref.id,
      });
    }

    // ============================================================
    // 30. WATER MANAGEMENT
    // ============================================================
    final cat30Ref = await firestore.collection('categories').add({
      'name': '30. Water Management',
      'description': 'Water risk assessment, sources, efficient use, quality, and irrigation',
      'order': 30,
    });

    final cat30DocTypes = [
      {
        'name': 'Water risk assessment',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water management plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of water conservation measures',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water permits/Usage license',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water use monitoring records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Irrigation system maintenance records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of water-saving technologies',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water use efficiency calculations per unit',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water analysis results for irrigation water',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water analysis results for spray application water',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Laboratory Accreditation Certificate (Water)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water treatment records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water Change Frequency Protocol (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Water Quality Monitoring Records (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Drench records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Irrigation scheduling records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Soil moisture records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Irrigation system verification records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Irrigation maintenance records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat30DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat30Ref.id,
      });
    }

    // ============================================================
    // 31. INTEGRATED PEST MANAGEMENT
    // ============================================================
    final cat31Ref = await firestore.collection('categories').add({
      'name': '31. Integrated Pest Management',
      'description': 'IPM implementation and pest monitoring',
      'order': 31,
    });

    final cat31DocTypes = [
      {
        'name': 'IPM plan',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Pest monitoring records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Orchard inspection records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Documentation of non-chemical control methods used',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Training records for IPM implementation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat31DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat31Ref.id,
      });
    }

    // ============================================================
    // 32. PLANT PROTECTION PRODUCTS
    // ============================================================
    final cat32Ref = await firestore.collection('categories').add({
      'name': '32. Plant Protection Products',
      'description': 'PPP management, application, storage, residue analysis, and handling',
      'order': 32,
    });

    final cat32DocTypes = [
      {
        'name': 'List of approved plant protection products (PPP/MRL Lists)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Operator competence certificates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Pesticide Drift Mitigation Plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Chemical Application records (product, date, rate, target, method, operator)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Spray Instructions',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Harvest date records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Warning system for PHI enforcement',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Container disposal procedure',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of chemical container disposal',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Accreditation of recycle company for empty chemical containers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Inventory of obsolete products',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Disposal records for obsolete products',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Procedure for handling surplus spray mixture',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Residue analysis results',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Corrective action records for exceeded limits',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Laboratory accreditation evidence (PPP)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Records of application of all substances used on crops',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of compliance with customer requirements (PPP)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Justification for use of substances',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Chemical store inspection',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Chemical inventory records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Spill management procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Mixing and handling procedures',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Emergency procedures for exposure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'PPE requirements and provision records (PPP)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Purchase invoices/receipts of agro-chemicals',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
    ];

    for (var docType in cat32DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat32Ref.id,
      });
    }

    // ============================================================
    // 33. POSTHARVEST HANDLING
    // ============================================================
    final cat33Ref = await firestore.collection('categories').add({
      'name': '33. Postharvest Handling',
      'description': 'Packing, storage, temperature control, pest control, labeling, and environmental monitoring (if applicable)',
      'order': 33,
    });

    final cat33DocTypes = [
      {
        'name': 'Facility layout map',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Cleaning and maintenance records (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Temperature control records (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Facility inspection checklists',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Foreign body control procedure',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Glass and hard plastic register',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Foreign body inspection records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Temperature/humidity monitoring records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
      {
        'name': 'Equipment calibration records (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Pest control plan (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Pest monitoring records (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Pest control contractor credentials',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Chemical usage records for pest control',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Site maps showing trap locations',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Labeling procedures',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Label verification records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Evidence of compliance with labeling regulations',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Traceability information on labels',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Environmental monitoring plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
        'hasFormTemplate': false,
      },
      {
        'name': 'Corrective action records (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Microbial analysis results',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Laboratory Accreditation certificate (Postharvest)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Air quality monitoring records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Filtration system maintenance records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Compressed gas specifications',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': false,
      },
      {
        'name': 'Inspection records for air handling systems',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
        'hasFormTemplate': true,
      },
    ];

    for (var docType in cat33DocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': cat33Ref.id,
      });
    }

    // Success message
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All GlobalG.A.P. categories and document types created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}