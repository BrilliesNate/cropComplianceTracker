import 'package:cropcompliance/views/admin/category_management_screen.dart';
import 'package:cropcompliance/views/admin/user_management_screen.dart';
import 'package:cropcompliance/views/audit_index/category_documents_screen.dart';
import 'package:flutter/material.dart';
import '../core/constants/route_constants.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/audit_tracker/audit_tracker_screen.dart';
import '../views/compliance_report/compliance_report_screen.dart';
import '../views/audit_index/audit_index_screen.dart';
import '../views/document_management/document_detail_screen.dart';
import '../views/document_management/document_upload_screen.dart';
import '../views/document_management/document_form_screen.dart';

class AppRouter {
  static String get initialRoute => RouteConstants.login;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteConstants.register:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteConstants.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case RouteConstants.auditTracker:
        return MaterialPageRoute(builder: (_) => const AuditTrackerScreen());
      case RouteConstants.complianceReport:
        return MaterialPageRoute(builder: (_) => const ComplianceReportScreen());
      case RouteConstants.auditIndex:
        return MaterialPageRoute(builder: (_) => const AuditIndexScreen());
      case RouteConstants.userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case RouteConstants.categoryManagement:
        return MaterialPageRoute(builder: (_) => const CategoryManagementScreen());
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
        return MaterialPageRoute(
          builder: (_) => DocumentUploadScreen(
            categoryId: args['categoryId'],
            documentTypeId: args['documentTypeId'],
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
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}