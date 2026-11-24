import 'package:cropCompliance/views/mobile/mobile_audit_checklist_screen.dart';
import 'package:cropCompliance/views/mobile/mobile_compliance_tracker_screen.dart';
import 'package:cropCompliance/views/mobile/mobile_payslips_screen.dart';
import 'package:cropCompliance/views/mobile/mobile_profile_screen.dart';
import 'package:cropCompliance/views/mobile/mobile_ui.dart';
import 'package:cropCompliance/views/mobile/mobile_upload_screen.dart';
import 'package:cropCompliance/company_document_override_screen.dart';
import 'package:cropCompliance/views/payslip/payslip_manager_screen.dart';
import 'package:cropCompliance/views/payslip/payslip_form_screen.dart';
import 'package:cropCompliance/views/payslip/payslip_detail_screen.dart';
import 'package:cropCompliance/views/payslip/bulk_payslip_screen.dart';
import 'package:cropCompliance/views/payslip/leave_management_screen.dart';
import 'package:cropCompliance/views/payslip/payslip_records_screen.dart';
import 'package:cropCompliance/views/payslip/timesheet/timesheet_screen.dart';
import 'package:cropCompliance/views/farmable/spray_records_screen.dart';
import 'package:cropCompliance/views/farmable/farmable_console_screen.dart';
import 'package:cropCompliance/views/farmable/farm_register_screen.dart';
import 'package:cropCompliance/views/farmable/farm_map_screen.dart';
import 'package:cropCompliance/views/admin/category_management_screen.dart';
import 'package:cropCompliance/views/admin/company_managment_screen.dart';
import 'package:cropCompliance/views/admin/form_config_management_screen.dart';
import 'package:cropCompliance/views/admin/user_management_screen.dart';
import 'package:cropCompliance/views/admin/data_fix_utility_screen.dart';
import 'package:cropCompliance/views/audit_index/category_documents_screen.dart';
import 'package:flutter/material.dart';
import '../core/constants/route_constants.dart';
import '../views/auth/login_screen.dart';
import '../views/dashboard/admin_dashboard_screen.dart';
import '../views/farms/my_farms_screen.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/dashboard/mobile_dashboard_screen.dart';
import '../views/audit_tracker/audit_tracker_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../videoAnimation.dart';
import '../views/compliance_report/compliance_report_screen.dart';
import '../views/audit_index/audit_index_screen.dart';
import '../views/document_management/document_detail_screen.dart';
import '../views/document_management/document_upload_screen.dart';
import '../views/document_management/document_form_screen.dart';
import '../views/shared/role_guard.dart';
import '../views/shared/admin_farm_gate.dart';
import '../providers/locale_provider.dart';

class AppRouter {
  static String get initialRoute => RouteConstants.login;

  /// Pages that show one farm's data (see [AdminFarmGate]).
  static const _farmPages = {
    RouteConstants.dashboard,
    RouteConstants.auditTracker,
    RouteConstants.complianceReport,
    RouteConstants.auditIndex,
    RouteConstants.payslipManager,
    RouteConstants.sprayRecords,
    RouteConstants.farmRegister,
    RouteConstants.farmMap,
  };

  /// Resolves the route, then wraps its page in a [RoleGuard] so role
  /// restrictions (e.g. auditors → Audit Index only) apply to every screen.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final route = _resolve(settings);
    if (route is MaterialPageRoute) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => RoleGuard(
          routeName: settings.name,
          child: _farmPages.contains(settings.name)
              // Admin with no farm open: Admin Dashboard / "Which farm?".
              ? AdminFarmGate(
                  isDashboard: settings.name == RouteConstants.dashboard,
                  child: route.builder(context),
                )
              : route.builder(context),
        ),
      );
    }
    return route;
  }

  static Route<dynamic> _resolve(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteConstants.register:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteConstants.dashboard:
        // Serve the mobile dashboard on narrow screens, the standard
        // dashboard on tablet/desktop.
        return MaterialPageRoute(
          builder: (_) => LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 650) {
                return const MobileDashboardScreen();
              }
              return const DashboardScreen();
            },
          ),
        );
      case RouteConstants.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case RouteConstants.myFarms:
        return MaterialPageRoute(builder: (_) => const MyFarmsScreen());
      case RouteConstants.auditTracker:
        return MaterialPageRoute(
            builder: (_) => _phoneOr(
                const MobileComplianceTrackerScreen(),
                const AuditTrackerScreen()));
      case RouteConstants.complianceReport:
        return MaterialPageRoute(builder: (_) => const ComplianceReportScreen());
      case RouteConstants.auditIndex:
        return MaterialPageRoute(
            builder: (_) => _phoneOr(const MobileAuditChecklistScreen(),
                const AuditIndexScreen()));
      case RouteConstants.profile:
        return MaterialPageRoute(builder: (_) => const MobileProfileScreen());
      case RouteConstants.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case RouteConstants.videoAd:
        return MaterialPageRoute(builder: (_) => const VideoAnimationScreen());
      case RouteConstants.userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case RouteConstants.categoryManagement:
        return MaterialPageRoute(builder: (_) => const CategoryManagementScreen());
      case RouteConstants.companyManagement:
        return MaterialPageRoute(builder: (_) => const CompanyManagementScreen());

      case RouteConstants.dataFixUtility:
        return MaterialPageRoute(builder: (_) => const DataFixUtilityScreen());

      case RouteConstants.overrid:
        return MaterialPageRoute(builder: (_) => const CompanyDocumentOverrideScreen());

      case RouteConstants.categoryDocuments:
        final args = settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (_) => CategoryDocumentsScreen(
            categoryId: args['categoryId'],
            categoryName: args['categoryName'],
          ),
        );
      case RouteConstants.documentDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(documentId: args['documentId']),
        );
      case RouteConstants.documentUpload:
        final args = settings.arguments as Map<String, dynamic>;
        print("DEBUG Router: documentUpload arguments: $args");
        return MaterialPageRoute(
          builder: (_) => _phoneOr(
            MobileUploadScreen(
              categoryId: args['categoryId'],
              documentTypeId: args['documentTypeId'],
              existingDocumentId: args['existingDocumentId'],
            ),
            DocumentUploadScreen(
              categoryId: args['categoryId'],
              documentTypeId: args['documentTypeId'],
              existingDocumentId: args['existingDocumentId'],
            ),
          ),
        );

      case RouteConstants.formConfigManagement:
        return MaterialPageRoute(builder: (_) => const FormConfigManagementScreen());
      case RouteConstants.formConfigEditor:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => FormConfigManagementScreen(
          ),
        );
      case RouteConstants.documentForm:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DocumentFormScreen(
            categoryId: args['categoryId'],
            documentTypeId: args['documentTypeId'],
          ),
        );
      case RouteConstants.payslipManager:
        return MaterialPageRoute(
            builder: (_) => _phoneOr(const MobilePayslipsScreen(),
                const PayslipManagerScreen()));

      case RouteConstants.payslipForm:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => PayslipFormScreen(
            payslipId: args['payslipId'],
            companyId: args['companyId'] ?? '',
            companyName: args['companyName'] ?? '',
          ),
        );

      case RouteConstants.payslipDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) =>
              PayslipDetailScreen(payslipId: args['payslipId']),
        );

      case RouteConstants.payslipBulkGenerate:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BulkPayslipScreen(
            companyId: args['companyId'] ?? '',
            companyName: args['companyName'] ?? '',
          ),
        );

      case RouteConstants.leaveManagement:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => LeaveManagementScreen(
            companyId: args['companyId'] ?? '',
            companyName: args['companyName'] ?? '',
          ),
        );

      case RouteConstants.payslipRecords:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => PayslipRecordsScreen(
            companyId: args['companyId'] ?? '',
            companyName: args['companyName'] ?? '',
          ),
        );

      case RouteConstants.timesheet:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TimesheetScreen(
            companyId: args['companyId'] ?? '',
            companyName: args['companyName'] ?? '',
          ),
        );

      case RouteConstants.sprayRecords:
        return MaterialPageRoute(builder: (_) => const SprayRecordsScreen());

      case RouteConstants.farmableConsole:
        return MaterialPageRoute(builder: (_) => const FarmableConsoleScreen());

      case RouteConstants.farmRegister:
        return MaterialPageRoute(builder: (_) => const FarmRegisterScreen());

      case RouteConstants.farmMap:
        return MaterialPageRoute(builder: (_) => const FarmMapScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(LocaleProvider.instance.l10n.routeNotFound('${settings.name}')),
            ),
          ),
        );
    }
  }

  /// Phones (narrow screens) get the mobile design; tablets and desktop keep
  /// the full layout. Decided by the space available, like the dashboard.
  static Widget _phoneOr(Widget phone, Widget wide) => LayoutBuilder(
        builder: (context, c) => isPhoneWidth(c.maxWidth) ? phone : wide,
      );
}
