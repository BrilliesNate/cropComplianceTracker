// Fairtrade (Hired Labour) Audit Index
// Source: "Fairtrade Audit Index (Hired Labour).pdf" (Nov 2026).
// Seeds the Fairtrade categories + document types tagged packageId:
// 'fairtrade'. Trigger once from the admin Data Fix Utility screen.
//
// Each item's flags, as listed in the PDF, are encoded as letters:
//   M  more than one document allowed
//   F  "two options" — upload OR fill in the in-app form (hasFormTemplate);
//      the form's questions are set up later in Form Configuration
//   E  has an expiry date
//   N  can be marked Not Applicable
//   S  specification needed (Specification box becomes required)
//   R  "{add reviewed date}" — uploader enters the date it was last reviewed
// No Fairtrade item needs signatures, and every item is uploadable.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _FtItem {
  final String name;
  final String flags;
  const _FtItem(this.name, this.flags);
}

class _FtSection {
  final String name;
  final List<_FtItem> items;
  const _FtSection(this.name, this.items);
}

const List<_FtSection> fairtradeSections = [
  _FtSection('1. General Requirements and Certification', [
    _FtItem('Valid Fairtrade certificate (FLOCERT)', 'MES'),
    _FtItem('FLOCERT certification agreement / acceptance of Terms and Conditions for Certification Services (FO48)', 'MES'),
    _FtItem('Application / questionnaire for Hired Labour certification', 'MS'),
    _FtItem('Annual FLOCERT / Fairtrade membership and certification fee proof of payment', 'MES'),
    _FtItem('Copy of the current Fairtrade Hired Labour Standard and applicable product standard on site', 'MS'),
    _FtItem('Proof of legal land tenure / land-use rights for all certified production sites', 'MS'),
    _FtItem('FLOCERT contact person and structural change notifications', 'MS'),
    _FtItem('FairInsight / Fairtrade Africa producer data and reporting (Producer Data Form and related reports)', 'MES'),
    _FtItem('Multi-estate structure documentation (head office, affiliated farms and accountability)', 'MNS'),
  ]),
  _FtSection('2. Commitment to Fairtrade', [
    _FtItem('Fairtrade Officer appointment and job description', 'ES'),
    _FtItem('Management commitment / mission statement referencing Fairtrade', 'ER'),
    _FtItem('Resource allocation / budget for Fairtrade activities', 'MES'),
    _FtItem('Written commitment to respecting human rights and the environment', 'R'),
    _FtItem('Evidence that audit results have been communicated to workers', 'MES'),
    _FtItem('Fairtrade work plan / management review of Fairtrade performance', 'MFES'),
  ]),
  _FtSection('3. Management of the Fairtrade Premium', [
    _FtItem('Fairtrade Premium Committee constitution / terms of reference', 'MS'),
    _FtItem('FPC election procedure and election records', 'MS'),
    _FtItem('Current FPC membership list (workers and management representatives, including gender representation)', 'MFES'),
    _FtItem('FPC meeting minutes', 'MFS'),
    _FtItem('General Assembly minutes (annual) and attendance register', 'MES'),
    _FtItem('Worker needs assessment used to inform the Premium Plan', 'MES'),
    _FtItem('Fairtrade Premium Plan approved by the General Assembly', 'MES'),
    _FtItem('Premium report / monitoring presented to the General Assembly', 'MES'),
    _FtItem('Separate Premium bank account confirmation and joint signing authorities (worker and management)', 'MS'),
    _FtItem('Premium bank statements (all Premium accounts, complete month sequence)', 'MES'),
    _FtItem('Premium expenditure invoices and payment records', 'MS'),
    _FtItem('Legal body for the Premium (NPC / association / trust registration and constitution)', 'MS'),
    _FtItem('Beneficial ownership filing for the Premium legal body', 'MENS'),
    _FtItem('Dissolution / decertification agreement for remaining Premium funds', 'S'),
    _FtItem('Premium project evidence (implementation records, distribution registers, photos)', 'MS'),
    _FtItem('Cash distribution records (maximum 20 percent, if applicable)', 'MENS'),
  ]),
  _FtSection('4. Capacity Building', [
    _FtItem('Fairtrade awareness training materials for all levels of the company', 'M'),
    _FtItem('Fairtrade awareness training registers (all workers, including seasonal workers)', 'MFES'),
    _FtItem('FPC member training records (participatory planning and financial management, partly during work time)', 'MES'),
    _FtItem('Worker representative / Freedom of Association training records', 'MES'),
    _FtItem('Women empowerment training, capacity building and assistance records', 'MS'),
    _FtItem('Skills development and equity programmes for disadvantaged and minority groups', 'MENS'),
    _FtItem('Child education support records linked to Fairtrade activities (if applicable)', 'MNS'),
  ]),
  _FtSection('5. Freedom from Discrimination', [
    _FtItem('Non-discrimination policy', 'R'),
    _FtItem('Sexual harassment policy and awareness records', 'MR'),
    _FtItem('Records of discrimination / harassment complaints and outcomes', 'MNS'),
    _FtItem('Evidence of equal opportunity in recruitment, training, promotion and remuneration', 'MES'),
  ]),
  _FtSection('6. Freedom from Forced Labour', [
    _FtItem('Forced labour / modern slavery policy or statement', 'R'),
    _FtItem('Modern Slavery Response Plan', 'ES'),
    _FtItem('Loan and advance procedures and tracking records', 'MNS'),
    _FtItem('Voluntary overtime procedures and records', 'MS'),
    _FtItem('Labour provider / recruiter contracts and no-fee recruitment evidence', 'MENS'),
  ]),
  _FtSection('7. Child Labour and Child Protection', [
    _FtItem('Age verification procedure and records', 'MS'),
    _FtItem('Child labour and child protection policy (Fairtrade wording)', 'R'),
    _FtItem('Child-protection remediation commitment / remediation plan', 'MNS'),
    _FtItem('Young worker risk assessments and working-hour records', 'MENS'),
  ]),
  _FtSection('8. Freedom of Association and Collective Bargaining', [
    _FtItem('Signed Fairtrade Freedom of Association Protocol (Annex 3)', 'S'),
    _FtItem("Right to Unionise Guarantee posted in the workplace (workers' language)", 'MS'),
    _FtItem('Freedom of Association protocol training records', 'MES'),
    _FtItem('Worker representative election records', 'MS'),
    _FtItem('Management-worker / worker committee meeting minutes', 'MFNS'),
    _FtItem('Collective bargaining agreement', 'MNS'),
    _FtItem('Trade union recognition agreement', 'MNS'),
    _FtItem('Point of contact for union / labour rights information (posted where required)', 'MNS'),
  ]),
  _FtSection('9. Conditions of Employment', [
    _FtItem('Employment contracts (samples of all types used, including seasonal and temporary)', 'MS'),
    _FtItem('Wage slips and payment records', 'MS'),
    _FtItem('Working hours, overtime and leave records', 'MS'),
    _FtItem('Legal minimum wage compliance evidence', 'MES'),
    _FtItem('Living wage gap analysis and wage increase plan', 'MES'),
    _FtItem('Deduction agreements and records', 'MNS'),
    _FtItem('Housing agreements / records (if housing is provided)', 'MNS'),
    _FtItem('Migrant worker records (if applicable)', 'MNS'),
    _FtItem('Piece rate / production target calculations (if applicable)', 'MNS'),
  ]),
  _FtSection('10. Occupational Health and Safety', [
    _FtItem('Occupational health and safety policy and risk assessments', 'MES'),
    _FtItem('Health and safety committee appointment and meeting minutes', 'MFES'),
    _FtItem('Health and safety training records and certificates', 'MES'),
    _FtItem('Accident, incident and occupational illness records', 'MNS'),
    _FtItem('PPE issue records', 'MFES'),
    _FtItem('Medical surveillance records', 'MENS'),
    _FtItem('Drinking water analysis and sanitation records', 'MES'),
    _FtItem('Emergency procedures, fire equipment servicing and drill records', 'MES'),
  ]),
  _FtSection('11. Human Rights and Environmental Due Diligence (HREDD)', [
    _FtItem('Written HREDD policy / commitment to respecting human rights and the environment', 'R'),
    _FtItem('Evidence that operational policies have been aligned with the HREDD commitment', 'MES'),
    _FtItem('HREDD awareness raising for board, management, staff and workers', 'MES'),
    _FtItem('Human rights and environmental risk assessment (at least every 3 years)', 'MES'),
    _FtItem('Human rights-based grievance mechanism (procedure, awareness and access, including anonymity)', 'MR'),
    _FtItem('Grievance / complaint logs and outcomes', 'MNS'),
    _FtItem('HREDD action plan', 'MFES'),
    _FtItem('Annual HREDD progress / monitoring report', 'MES'),
    _FtItem('Remediation procedure and remediation records', 'MNS'),
    _FtItem('Stakeholder engagement and HREDD dialogue records', 'MENS'),
  ]),
  _FtSection('12. Environmental Development', [
    _FtItem('Environmental management plan / appointed environmental officer', 'MES'),
    _FtItem('Fairtrade Hazardous Materials List (current HML) on site', 'MS'),
    _FtItem('Pesticide / agrochemical inventory cross-checked against the HML (red, orange and yellow lists)', 'MFES'),
    _FtItem('Orange-list phase-out / reduction plan', 'MENS'),
    _FtItem('Integrated pest management records', 'MES'),
    _FtItem('Soil and water management plan', 'MES'),
    _FtItem('GMO-free declaration / procedure', 'S'),
    _FtItem('Biodiversity and buffer-zone records', 'MNS'),
    _FtItem('Waste management procedures and disposal records (including empty pesticide containers)', 'MES'),
    _FtItem('Energy use and greenhouse gas records / reduction plan', 'MENS'),
    _FtItem('Environmental permits and impact assessments (if applicable)', 'MENS'),
  ]),
  _FtSection('13. Trade, Traceability and Fairtrade Mark', [
    _FtItem('Buyer / trader Fairtrade contracts or addenda (current harvest / season)', 'MES'),
    _FtItem('Fairtrade sales, volume and delivery records', 'MES'),
    _FtItem('Physical and documentary traceability from field to buyer (Fairtrace or equivalent)', 'MES'),
    _FtItem('Fairtrade Minimum Price payment evidence', 'MES'),
    _FtItem('Fairtrade Premium payment evidence from the buyer to the nominated Premium account', 'MES'),
    _FtItem('Product standard records (Fresh Fruit / wine grapes or other applicable product standard)', 'MENS'),
    _FtItem('Fairtrade Mark artwork approval / trademark licence (if the Mark is used)', 'MENS'),
  ]),
  _FtSection('14. FLOCERT Audits and Corrective Actions', [
    _FtItem('Previous FLOCERT audit reports and closing reports', 'MES'),
    _FtItem('Confirmation of non-conformities and requests for corrective measures', 'MES'),
    _FtItem('Corrective action plans and evidence of closed non-conformities', 'MES'),
    _FtItem('Internal Fairtrade self-assessment / audit preparation', 'MES'),
  ]),
];

/// Firestore document-type fields for one item.
Map<String, dynamic> fairtradeTypeFields(String name, String flags) => {
      'name': name,
      'allowMultipleDocuments': flags.contains('M'),
      'isUploadable': true,
      'hasExpiryDate': flags.contains('E'),
      'hasNotApplicableOption': flags.contains('N'),
      'requiresSignature': false,
      'signatureCount': 0,
      'hasFormTemplate': flags.contains('F'),
      'requiresSpecification': flags.contains('S'),
      'hasReviewedDate': flags.contains('R'),
    };

/// Seeds every Fairtrade category and document type. Safe to tap twice: it
/// skips when Fairtrade categories already exist.
Future<void> setupFairtradeData(BuildContext context) async {
  final firestore = FirebaseFirestore.instance;

  final existing = await firestore
      .collection('categories')
      .where('packageId', isEqualTo: 'fairtrade')
      .limit(1)
      .get();
  if (existing.docs.isNotEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fairtrade package already exists — skipping.')));
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
        Text('Setting up Fairtrade categories…'),
      ]),
    ),
  );

  var types = 0;
  try {
    for (var i = 0; i < fairtradeSections.length; i++) {
      final section = fairtradeSections[i];
      final catRef = firestore.collection('categories').doc();
      final batch = firestore.batch();
      batch.set(catRef, {
        'name': section.name,
        'description': '',
        'order': i + 1,
        'packageId': 'fairtrade',
      });
      for (final item in section.items) {
        batch.set(firestore.collection('documentTypes').doc(), {
          ...fairtradeTypeFields(item.name, item.flags),
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
        content: Text('Fairtrade set up: ${fairtradeSections.length} '
            'categories, $types document types. Turn it on per company in '
            'Company Management.'),
      ));
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fairtrade setup failed: $e')));
    }
  }
}
