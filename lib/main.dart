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
import 'services/auto_backup_service.dart';
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
  final _autoBackupService = AutoBackupService();

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
    WidgetsBinding.instance.addObserver(this);
    _shareChannel.setMethodCallHandler(_handleNativeMethodCall);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final settings = context.read<SettingsProvider>();
    final sessions = context.read<SessionProvider>();

    // A failing step (e.g. secure storage) must not leave the app stuck on
    // the loading screen.
    try {
      await settings.load();
    } catch (e) {
      debugPrint('Settings load failed: $e');
    }
    try {
      await sessions.load();
      await _autoBackupService.runDailyBackupIfNeeded(
        sessions: sessions.sessions,
        settings: settings.settings,
        onBackupDone: settings.setLastAutoBackupAt,
      );
    } catch (e) {
      debugPrint('Sessions load or backup failed: $e');
    }
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
    // Compact labels keep "Historique" on one line on narrow phones, even
    // with a larger system font size.
    const navigationBarTheme = NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, letterSpacing: 0, fontWeight: FontWeight.w500),
      ),
    );
    const lightAccent = Color(0xFF2F6FDE);
    const darkAccent = Color(0xFF9CC3FF);

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
        navigationBarTheme: navigationBarTheme.copyWith(
          backgroundColor: Colors.white,
          indicatorColor: lightAccent.withValues(alpha: 0.18),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? lightAccent
                  : deepBlue.withValues(alpha: 0.7),
            ),
          ),
        ),
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
          backgroundColor: deepBlue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        navigationBarTheme: navigationBarTheme.copyWith(
          backgroundColor: darkCard,
          indicatorColor: darkAccent.withValues(alpha: 0.22),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? darkAccent
                  : Colors.white70,
            ),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: deepBlue,
          primary: darkAccent,
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
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: darkCard,
          foregroundColor: darkAccent,
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
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Accueil',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timer_outlined),
                    selectedIcon: Icon(Icons.timer),
                    label: 'Session',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: 'Historique',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.description_outlined),
                    selectedIcon: Icon(Icons.description),
                    label: 'Rapport',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Réglages',
                  ),
                ],
              ),
            ),
    );
  }
}
