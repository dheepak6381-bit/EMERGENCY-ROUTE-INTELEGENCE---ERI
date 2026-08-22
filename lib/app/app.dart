import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/color_palette.dart';
import '../../app/theme/app_theme.dart';
import '../ui/dashboard/dashboard_screen.dart';

class EriApp extends ConsumerWidget {
  const EriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ERI — Emergency Route Intelligence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
