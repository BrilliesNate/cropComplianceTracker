import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';

/// Screens an auditor may open: the farm picker (if they have several farms), the Audit Index, the documents inside a
/// category, a single (approved) document, and the sign-in screen so they can
/// log out. Everything else — dashboard, tracker, report, payslips, Farmable,
/// notifications, admin — is off limits.
const Set<String> auditorAllowedRoutes = {
  RouteConstants.login,
  RouteConstants.register,
  RouteConstants.myFarms,
  RouteConstants.auditIndex,
  RouteConstants.categoryDocuments,
  RouteConstants.documentDetail,
};

/// Wraps every routed screen. If the signed-in user is an auditor and the
/// screen isn't on their allow-list, they are sent to the Audit Index instead.
///
/// This is the navigation-level half of the auditor restriction (the menu is
/// also trimmed, and Firestore rules enforce it on the data itself).
class RoleGuard extends StatelessWidget {
  final String? routeName;
  final Widget child;

  const RoleGuard({Key? key, required this.routeName, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final blocked = auth.isAuditer &&
        routeName != null &&
        !auditorAllowedRoutes.contains(routeName);

    if (!blocked) return child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(RouteConstants.auditIndex);
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
