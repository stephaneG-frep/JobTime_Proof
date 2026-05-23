import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/session_timer_screen.dart';
import 'screens/settings_screen.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, SessionProvider>(
          create: (_) => SessionProvider(),
          update: (_, settingsProvider, sessionProvider) =>
              sessionProvider ?? SessionProvider(),
        ),
      ],
      child: const JobTimeProofApp(),
    ),
  );
}

class JobTimeProofApp extends StatefulWidget {
  const JobTimeProofApp({super.key});

  @override
  State<JobTimeProofApp> createState() => _JobTimeProofAppState();
}

class _JobTimeProofAppState extends State<JobTimeProofApp> {
  int _index = 0;
  bool _ready = false;

  final _pages = const [
    DashboardScreen(),
    SessionTimerScreen(),
    HistoryScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settings = context.read<SettingsProvider>();
    final sessions = context.read<SessionProvider>();

    await settings.load();
    await sessions.load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    const deepBlue = Color(0xFF123A6F);
    const offWhite = Color(0xFFF6F7FB);
    const validationGreen = Color(0xFF2E9E5B);
    const softOrange = Color(0xFFE59A43);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobTime Proof',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: deepBlue,
          primary: deepBlue,
          surface: offWhite,
          tertiary: softOrange,
          secondary: validationGreen,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: offWhite,
        cardTheme: CardThemeData(
          elevation: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: deepBlue,
        ),
      ),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Scaffold(
              appBar: AppBar(title: const Text('JobTime Proof')),
              body: _pages[_index],
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    label: 'Tableau de bord',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timer_outlined),
                    label: 'Session',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history),
                    label: 'Historique',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.description_outlined),
                    label: 'Rapport',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Paramètres',
                  ),
                ],
              ),
            ),
    );
  }
}
