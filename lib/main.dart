import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/session_timer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
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

class _JobTimeProofAppState extends State<JobTimeProofApp>
    with WidgetsBindingObserver {
  static const MethodChannel _shareChannel = MethodChannel(
    'jobtime_proof/share',
  );
  int _index = 0;
  bool _ready = false;

  final _pages = const [
    DashboardScreen(),
    SessionTimerScreen(),
    HistoryScreen(),
    ReportScreen(),
    SettingsScreen(),
    HelpScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shareChannel.setMethodCallHandler(_handleNativeMethodCall);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settings = context.read<SettingsProvider>();
    final sessions = context.read<SessionProvider>();

    await settings.load();
    await sessions.load();
    await _pullSharedUrlFromNative();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _pullSharedUrlFromNative() async {
    try {
      final url = await _shareChannel.invokeMethod<String>(
        'getAndClearSharedUrl',
      );
      if (!mounted || url == null || url.trim().isEmpty) return;
      context.read<SessionProvider>().setPendingSharedUrl(url);
    } catch (_) {
      // Ignore native channel errors to keep app startup resilient.
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method != 'onSharedUrl') return;
    final sharedUrl = call.arguments as String?;
    if (!mounted || sharedUrl == null || sharedUrl.trim().isEmpty) return;
    context.read<SessionProvider>().setPendingSharedUrl(sharedUrl);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pullSharedUrlFromNative();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<SettingsProvider>().settings.darkModeEnabled;
    const deepBlue = Color(0xFF123A6F);
    const offWhite = Color(0xFFF6F7FB);
    const validationGreen = Color(0xFF2E9E5B);
    const softOrange = Color(0xFFE59A43);
    const darkSurface = Color(0xFF11161F);
    const darkCard = Color(0xFF1A2230);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobTime Proof',
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: deepBlue,
          primary: const Color(0xFF9CC3FF),
          secondary: const Color(0xFF69C98B),
          tertiary: softOrange,
          surface: darkSurface,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: darkSurface,
        cardTheme: CardThemeData(
          color: darkCard,
          elevation: 0.6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
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
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    label: 'Aide',
                  ),
                ],
              ),
            ),
    );
  }
}
