// // Setup initial data method with all 12 categories
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// Future<void> _setupInitialData() async {
//   final firestore = FirebaseFirestore.instance;
//
//   // Show loading dialog
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => const AlertDialog(
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircularProgressIndicator(),
//           SizedBox(height: 16),
//           Text('Setting up document categories...'),
//         ],
//       ),
//     ),
//   );
//
//   try {
//     // 1. Business Information and Compliance
//     final businessCatRef = await firestore.collection('categories').add({
//       'name': 'Business Information and Compliance',
//       'description': 'Registration, tax, and compliance documentation',
//       'order': 1,
//     });
//
//     // Business Information document types
//     final businessDocTypes = [
//       {
//         'name': 'Company Registration Documents',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Tax Compliance Certificates',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Workmans Compensation Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'BEE Certification Documentation',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Company Organisational Chart',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Site Maps/Layouts',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Business Licences and Permits',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'WIETA/SIZA Membership Documentation',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in businessDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': businessCatRef.id,
//       });
//     }
//
//     // 2. Management Systems
//     final managementCatRef = await firestore.collection('categories').add({
//       'name': 'Management Systems',
//       'description': 'Policies, procedures, and risk assessments',
//       'order': 2,
//     });
//
//     // Management Systems document types
//     final managementDocTypes = [
//       {
//         'name': 'Ethical Code of Conduct',
//         'allowMultipleDocuments': false,
//         'isUploadable': false,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Document Control Procedure',
//         'allowMultipleDocuments': false,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Company Policies',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Appointments (Ethical & Health and Safety)',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Risk Assessments',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Internal Audits Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Social Compliance Improvement Plans',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Previous WIETA/SIZA Audit Reports',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Evidence of Closed Non-Conformances',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Continuous Improvement Plans',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in managementDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': managementCatRef.id,
//       });
//     }
//
//     // 3. Employment Documentation
//     final employmentCatRef = await firestore.collection('categories').add({
//       'name': 'Employment Documentation',
//       'description': 'Contracts, agreements, and employee records',
//       'order': 3,
//     });
//
//     final employmentDocTypes = [
//       {
//         'name': 'Employment Contracts',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Housing Agreements/Contracts',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'List of Employees',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Employee Contact Details Form',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Medical Screening Form',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Labour Procedures',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Disciplinary Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Proof of Identity and Right to Work Documents',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Records of Migrant Workers',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'EEA1 Forms',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Employment Equity Documentation',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in employmentDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': employmentCatRef.id,
//       });
//     }
//
//     // 4. Child Labor and Young Workers
//     final childLaborCatRef = await firestore.collection('categories').add({
//       'name': 'Child Labor and Young Workers',
//       'description': 'Age verification and young worker protections',
//       'order': 4,
//     });
//
//     final childLaborDocTypes = [
//       {
//         'name': 'Age Verification Procedure',
//         'allowMultipleDocuments': false,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Records of Young Workers',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Young Worker Risk Assessments',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Records of Working Hours for Young Workers',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Education Support Programs',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Child Labor Remediation Plan',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in childLaborDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': childLaborCatRef.id,
//       });
//     }
//
//     // 5. Forced Labor Prevention
//     final forcedLaborCatRef = await firestore.collection('categories').add({
//       'name': 'Forced Labor Prevention',
//       'description': 'Procedures and records to prevent forced labor',
//       'order': 5,
//     });
//
//     final forcedLaborDocTypes = [
//       {
//         'name': 'Loan and Advance Procedures',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Records of Loan Payments and Tracking',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Procedures for Voluntary Overtime',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Contracts with Labor Providers/Recruiters',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in forcedLaborDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': forcedLaborCatRef.id,
//       });
//     }
//
//     // 6. Wages and Working Hours
//     final wagesCatRef = await firestore.collection('categories').add({
//       'name': 'Wages and Working Hours',
//       'description': 'Wage documentation and working hour records',
//       'order': 6,
//     });
//
//     final wagesDocTypes = [
//       {
//         'name': 'SARS Registration',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'UIF Records and Payments',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Wage Slips',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Time Recording System Documentation',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Working Hours',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Overtime Authorization Forms/Exemptions',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Night Allowance',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Production Targets and Piece Rate Calculations',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Records of Bonuses or Incentives',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Deduction Agreements',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Loan Agreements',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Minimum Wage Calculations and Compliance Evidence',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Leave Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Public Holiday Work and Pay Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in wagesDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': wagesCatRef.id,
//       });
//     }
//
//     // 7. Freedom of Association
//     final associationCatRef = await firestore.collection('categories').add({
//       'name': 'Freedom of Association',
//       'description': 'Worker representation and collective bargaining',
//       'order': 7,
//     });
//
//     final associationDocTypes = [
//       {
//         'name': 'Records of Worker Representative Elections',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Worker Committee Meeting Minutes',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Management Review Meeting Minutes',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Records of Collective Bargaining Agreements',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Trade Union Recognition Agreements',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in associationDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': associationCatRef.id,
//       });
//     }
//
//     // 8. Training and Development
//     final trainingCatRef = await firestore.collection('categories').add({
//       'name': 'Training and Development',
//       'description': 'Training materials and records',
//       'order': 8,
//     });
//
//     final trainingDocTypes = [
//       {
//         'name': 'Induction Training Materials',
//         'allowMultipleDocuments': false,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Induction Training Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Skills Training Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Health and Safety Training Materials',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Social Compliance Training Materials',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Training Schedule',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in trainingDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': trainingCatRef.id,
//       });
//     }
//
//     // 9. Health and Safety
//     final healthSafetyCatRef = await firestore.collection('categories').add({
//       'name': 'Health and Safety',
//       'description': 'Procedures, records, and safety documentation',
//       'order': 9,
//     });
//
//     final healthSafetyDocTypes = [
//       {
//         'name': 'Emergency & Safety Procedures',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Health and Safety Committee Meeting Minutes',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Workplace Safety Inspections',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Accident and Incident Reports',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Training Certificates',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Records of Fire Drills and Evacuations',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Fire Permit Fire Association',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Fire Extinguishers Service Certificate',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Forklift Load Test',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Pressure Test Compressor',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Machine and Vehicle Safety Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Asbestos Register',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Procedure Asbestos Maintenance',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Removal and Management Plan',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Asbestos Survey',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'PDPs/Licenses',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'COCs',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Analysis Potable Water',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Septic Tank Pump Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Personal Protective Equipment (PPE) Distribution Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Medical Surveillance Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Hygiene Inspection Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Stacking Permit',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in healthSafetyDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': healthSafetyCatRef.id,
//       });
//     }
//
//     // 10. Chemical and Pesticide Management
//     final chemicalCatRef = await firestore.collection('categories').add({
//       'name': 'Chemical and Pesticide Management',
//       'description': 'Chemical handling, storage, and safety records',
//       'order': 10,
//     });
//
//     final chemicalDocTypes = [
//       {
//         'name': 'Chemical Inventory List',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Safety Data Sheets (SDS)',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Chemical Handling Procedures',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Chemical Storage Facility Specifications',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'PPE Specific for Chemical Handling',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'Re-entry Interval Procedure',
//         'allowMultipleDocuments': false,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Medical Check-up Records for Chemical Handlers',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Pesticide Containers Disposal Certificate',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in chemicalDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': chemicalCatRef.id,
//       });
//     }
//
//     // 11. Labour and Service Providers
//     final serviceProvidersCatRef = await firestore.collection('categories').add({
//       'name': 'Labour and Service Providers',
//       'description': 'Contractor agreements and compliance records',
//       'order': 11,
//     });
//
//     final serviceProvidersDocTypes = [
//       {
//         'name': 'Service Providers/Contractor Code of Conduct',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': true,
//         'signatureCount': 1,
//       },
//       {
//         'name': 'List of Contractors and Service Providers',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Section 37(2) Agreements',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Contractor Compliance Evaluation Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in serviceProvidersDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': serviceProvidersCatRef.id,
//       });
//     }
//
//     // 12. Environmental and Community Impact
//     final environmentalCatRef = await firestore.collection('categories').add({
//       'name': 'Environmental and Community Impact',
//       'description': 'Environmental procedures and community engagement',
//       'order': 12,
//     });
//
//     final environmentalDocTypes = [
//       {
//         'name': 'Waste Management Procedures',
//         'allowMultipleDocuments': true,
//         'isUploadable': false,
//         'hasExpiryDate': false,
//         'hasNotApplicableOption': false,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Waste Removal Records',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Community Engagement Activities',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Records of Environmental Permits',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//       {
//         'name': 'Environmental Impact Assessments',
//         'allowMultipleDocuments': true,
//         'isUploadable': true,
//         'hasExpiryDate': true,
//         'hasNotApplicableOption': true,
//         'requiresSignature': false,
//         'signatureCount': 0,
//       },
//     ];
//
//     for (var docType in environmentalDocTypes) {
//       await firestore.collection('documentTypes').add({
//         ...docType,
//         'categoryId': environmentalCatRef.id,
//       });
//     }
//
//     // Success message
//     if (mounted) {
//       Navigator.pop(context); // Close loading dialog
//
//       // Refresh providers
//       final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
//       await categoryProvider.initialize();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('All categories and document types created successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   } catch (e) {
//     if (mounted) {
//       Navigator.pop(context); // Close loading dialog
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error setting up data: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }