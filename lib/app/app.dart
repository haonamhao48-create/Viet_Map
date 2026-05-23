import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class VNMapApp extends StatelessWidget {
  const VNMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VN Map App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}