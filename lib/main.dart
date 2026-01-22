import 'package:cropCompliance/providers/audit_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/route_provider.dart';
import 'package:cropCompliance/views/document_management/forms/company_orfanizational_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes/router.dart';
import 'providers/auth_provider.dart';
import 'providers/document_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );



  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ChangeNotifierProvider(create: (_) => AuditProvider()),
      ChangeNotifierProvider(create: (_) => RouteProvider()),
    ],
    child: const AgriComplianceApp(),
  ));
}

class AgriComplianceApp extends StatelessWidget {
  const AgriComplianceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Agricultural Compliance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
      // home: const CompanyOrganizationalChart(),
    );
  }
}