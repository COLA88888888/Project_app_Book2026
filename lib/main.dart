import 'package:flutter/material.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

import 'core/database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm up backend connection in background
  DatabaseHelper.getBaseUrl().catchError((_) => '');
  runApp(const EduApp());
}

class EduApp extends StatelessWidget {
  const EduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Edu App',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
