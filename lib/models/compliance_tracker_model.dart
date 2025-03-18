// models.dart - Data models for the Compliance Tracker

import 'package:cropcompliance/components/document_item_comp.dart';
import 'package:flutter/material.dart';

// Document item model


// Checklist category model
class ChecklistCategory {
  final String name;
  final List<ChecklistItem> items;

  ChecklistCategory({
    required this.name,
    required this.items,
  });

  // Calculate completion percentage for this category
  double get completionPercentage {
    if (items.isEmpty) return 0;
    int completedCount = items.where((item) => item.isCompleted).length;
    return (completedCount / items.length) * 100;
  }
}

// Checklist item model
class ChecklistItem {
  final String name;
  bool isCompleted;
  String? documentFilePath;
  DocumentItem? linkedDocument;

  ChecklistItem({
    required this.name,
    this.isCompleted = false,
    this.documentFilePath,
    this.linkedDocument,
  });

  // audit index
  // list of docs -> has expiory dates
  //Name
  // Ethical code of conduct: hase expiory date. can take multiple documents

  // compliance tracker card.
  // catagory heading
  // list of docs. in order of date uploaded. each one you will need to be able to view and update

  // Convert to Firebase data
  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'documentFilePath': documentFilePath,
      'linkedDocumentId': linkedDocument?.id,
    };
  }
}

// Enums for Document properties
enum Priority {
  high,
  medium,
  low,
}

enum DocumentStatus {
  approved,
  rejected,
  pending,
}

enum SortOption {
  priority,
  status,
  expiryDate,
  title,
}

enum FilterOption {
  approved,
  rejected,
  pending,
  expiringSoon,
  expired,
  highPriority,
}

// Function to initialize the audit checklist
List<ChecklistCategory> initializeAuditChecklist() {
  return [
    ChecklistCategory(
      name: "1. Business Information and Compliance",
      items: [
        ChecklistItem(name: "Company registration documents"),
        ChecklistItem(name: "Tax Compliance Certificates"),
        ChecklistItem(name: "Workmans Compensation records"),
        ChecklistItem(name: "BEE certification documentation (if applicable)"),
        ChecklistItem(name: "Company organisational chart"),
        ChecklistItem(name: "Site maps/layouts"),
        ChecklistItem(name: "Business licences and permits"),
        ChecklistItem(name: "WIETA/SIZA Membership documentation"),
      ],
    ),
    ChecklistCategory(
      name: "2. Management Systems",
      items: [
        ChecklistItem(name: "Ethical code of conduct"),
        ChecklistItem(name: "Document control system/procedures"),
        ChecklistItem(name: "Company policies and procedures regarding labour"),
        ChecklistItem(name: "Appointments (Ethical & Health and Safety)"),
        ChecklistItem(name: "Risk assessments"),
        ChecklistItem(name: "Internal audits records"),
        ChecklistItem(name: "Social compliance improvement plans"),
        ChecklistItem(name: "Previous WIETA/SIZA audit reports and corrective actions"),
        ChecklistItem(name: "Continuous improvement plans"),
      ],
    ),
    ChecklistCategory(
      name: "3. Employment Documentation",
      items: [
        ChecklistItem(name: "Employment contracts (samples of all types used)"),
        ChecklistItem(name: "Housing agreements/contracts (if applicable)"),
        ChecklistItem(name: "Records of worker information (age, gender, nationality, etc.)"),
        ChecklistItem(name: "Employee contact details form, medical screening form"),
        ChecklistItem(name: "Employee handbook/manual"),
        ChecklistItem(name: "Disciplinary records"),
        ChecklistItem(name: "Organogram"),
        ChecklistItem(name: "Recruitment and selection procedures"),
        ChecklistItem(name: "Termination and resignation procedures"),
        ChecklistItem(name: "Personnel files (samples)"),
        ChecklistItem(name: "Proof of identity and right to work documents"),
        ChecklistItem(name: "Records of migrant workers (if applicable)"),
        ChecklistItem(name: "Employment Equity records - business as well as EEA1 forms (if applicable)"),
      ],
    ),
    ChecklistCategory(
      name: "4. Child Labor and Young Workers",
      items: [
        ChecklistItem(name: "Age verification procedure"),
        ChecklistItem(name: "Records of young workers (if applicable)"),
        ChecklistItem(name: "Young worker risk assessments"),
        ChecklistItem(name: "Records of working hours for young workers"),
        ChecklistItem(name: "Education support programs (if applicable)"),
        ChecklistItem(name: "Child labor remediation plan (if needed)"),
      ],
    ),
    ChecklistCategory(
      name: "5. Forced Labor Prevention",
      items: [
        ChecklistItem(name: "Loan and advance procedures"),
        ChecklistItem(name: "Records of deposits or security payments"),
        ChecklistItem(name: "Procedures for voluntary overtime"),
        ChecklistItem(name: "Contracts with labor providers/recruiters and monitoring"),
      ],
    ),
    ChecklistCategory(
      name: "6. Wages and Working Hours",
      items: [
        ChecklistItem(name: "SARS registration"),
        ChecklistItem(name: "UIF records and payments"),
        ChecklistItem(name: "Payroll records (last 12 months)"),
        ChecklistItem(name: "Wage slips/pay stubs (samples)"),
        ChecklistItem(name: "Working Hours; Overtime authorization forms/exemptions"),
        ChecklistItem(name: "Time recording system documentation"),
        ChecklistItem(name: "Production targets and piece rate calculations (if applicable)"),
        ChecklistItem(name: "Records of bonuses, incentives, and deductions"),
        ChecklistItem(name: "Minimum wage calculations and compliance evidence"),
        ChecklistItem(name: "Leave records (annual, sick, maternity, etc.)"),
        ChecklistItem(name: "Public holiday work records"),
      ],
    ),
    ChecklistCategory(
      name: "7. Freedom of Association",
      items: [
        ChecklistItem(name: "Records of worker representative elections"),
        ChecklistItem(name: "Worker committee meeting minutes"),
        ChecklistItem(name: "Suggestion box procedures and records"),
        ChecklistItem(name: "Communication of workplace policies (evidence)"),
        ChecklistItem(name: "Management review meeting minutes"),
        ChecklistItem(name: "Records of collective bargaining agreements (if applicable)"),
        ChecklistItem(name: "Trade union recognition agreements (if applicable)"),
        ChecklistItem(name: "Communication channels between management and workers"),
        ChecklistItem(name: "Worker forum documentation"),
      ],
    ),
    ChecklistCategory(
      name: "8. Training and Development",
      items: [
        ChecklistItem(name: "Induction training materials and records"),
        ChecklistItem(name: "Skills training records"),
        ChecklistItem(name: "Supervisory training materials"),
        ChecklistItem(name: "Health and safety training materials"),
        ChecklistItem(name: "Social compliance training materials"),
        ChecklistItem(name: "Training schedule"),
        ChecklistItem(name: "Evidence of career development opportunities"),
      ],
    ),
    ChecklistCategory(
      name: "9. Health and Safety",
      items: [
        ChecklistItem(name: "Risk assessments"),
        ChecklistItem(name: "Safety Procedures"),
        ChecklistItem(name: "Health and safety committee meeting minutes"),
        ChecklistItem(name: "Workplace safety inspections"),
        ChecklistItem(name: "Accident and incident reports"),
        ChecklistItem(name: "Emergency procedures"),
        ChecklistItem(name: "Training certificates for applicable categories"),
        ChecklistItem(name: "Records of fire drills and evacuations"),
        ChecklistItem(name: "Fire Permit Fire Association"),
        ChecklistItem(name: "Fire Extinguishers Service Certificate"),
        ChecklistItem(name: "Forklift Load Test (if applicable)"),
        ChecklistItem(name: "Pressure Test Compressor"),
        ChecklistItem(name: "Machine and vehicle safety records"),
        ChecklistItem(name: "Asbestos register and management plan"),
        ChecklistItem(name: "Asbestos survey"),
        ChecklistItem(name: "PDP's of persons applicable"),
        ChecklistItem(name: "COC's"),
        ChecklistItem(name: "Analysis potable water"),
        ChecklistItem(name: "Septic tank pump records (if applicable)"),
        ChecklistItem(name: "PPE distribution records"),
        ChecklistItem(name: "Medical surveillance records"),
        ChecklistItem(name: "Hygiene inspection records"),
        ChecklistItem(name: "Stacking Permit (if applicable)"),
      ],
    ),
    ChecklistCategory(
      name: "10. Chemical and Pesticide Management",
      items: [
        ChecklistItem(name: "Chemical inventory list"),
        ChecklistItem(name: "Safety Data Sheets (SDS) for all chemicals"),
        ChecklistItem(name: "Chemical handling procedures"),
        ChecklistItem(name: "Chemical storage facility specifications"),
        ChecklistItem(name: "Chemical applicator training records"),
        ChecklistItem(name: "PPE specific for chemical handling"),
        ChecklistItem(name: "Spraying records and schedules"),
        ChecklistItem(name: "Re-entry interval compliance records"),
        ChecklistItem(name: "Medical check-up records for chemical handlers"),
        ChecklistItem(name: "Pesticide disposal procedures"),
      ],
    ),
    ChecklistCategory(
      name: "11. Labour and Service Providers",
      items: [
        ChecklistItem(name: "Service Providers/Contractor code of conduct"),
        ChecklistItem(name: "List of contractors and service providers"),
        ChecklistItem(name: "Section 37(2) agreements"),
        ChecklistItem(name: "Contractor compliance evaluation records"),
      ],
    ),
    ChecklistCategory(
      name: "12. Environmental and Community Impact",
      items: [
        ChecklistItem(name: "Waste management procedures"),
        ChecklistItem(name: "Community engagement activities"),
        ChecklistItem(name: "Records of environmental permits"),
        ChecklistItem(name: "Environmental impact assessments"),
      ],
    ),
    ChecklistCategory(
      name: "13. Previous Audits and Certifications",
      items: [
        ChecklistItem(name: "Previous WIETA/SIZA audit reports"),
        ChecklistItem(name: "Corrective action plans from previous audits"),
        ChecklistItem(name: "Evidence of closed non-conformances"),
        ChecklistItem(name: "Internal audit reports"),
        ChecklistItem(name: "Corrective action plans for internal audits"),
      ],
    )
  ];
}