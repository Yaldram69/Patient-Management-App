// lib/main.dart
import 'package:flutter/material.dart';
import 'package:patient_manager_app/screens/login_screen.dart';
import 'package:patient_manager_app/screens/patient_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/patient.g.dart';
import 'services/auth.dart';
import 'services/db.dart';
import 'services/theme_provider.dart';
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters only once
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PatientAdapter());
  }

  // Open your box before runApp
  await DatabaseService.openPatientBox();

  // Create theme provider (also opens settings box)
  final themeProvider = await ThemeProvider.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProv, _) {
      final accent = themeProv.accentColor;
      final dark = themeProv.isDark;
      return MaterialApp(
        title: 'Patient App',
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        theme: AppTheme.themeData(accentColor: accent, darkMode: false),
        darkTheme: AppTheme.themeData(accentColor: accent, darkMode: true),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        routes: {
          '/login': (_) => const LoginScreen(),
          '/patients': (_) => const PatientListScreen(),
        },
      );
    });
  }
}
