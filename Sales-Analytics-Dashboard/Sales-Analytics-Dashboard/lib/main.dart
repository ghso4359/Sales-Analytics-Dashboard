import 'package:flutter/material.dart';
import 'package:sales_analytics_dashboard/pages/analytics_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SalesAnalyticsApp());
}

class SalesAnalyticsApp extends StatelessWidget {
  const SalesAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Analytics Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      ),
      home: const AnalyticsPage(),
    );
  }
}
