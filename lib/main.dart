import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/journey_screen.dart';
import 'screens/library_screen.dart';
import 'screens/mixer_screen.dart';
import 'screens/tone_test_screen.dart';
import 'services/analytics_service.dart';
import 'services/audio_engine.dart';
import 'services/journey_engine.dart';
import 'services/llm_service.dart';
import 'services/mood_engine.dart';
import 'services/motif_engine.dart';
import 'services/storage_service.dart';
import 'services/tone_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.setDefaults({
    'motif_density_sleep': 0.25,
    'motif_density_relax': 0.40,
    'motif_density_focus': 0.40,
    'motif_density_energize': 0.70,
    'soundscape_volume': 0.55,
    'nature_volume': 0.35,
    'noise_volume': 0.30,
    'binaural_volume': 0.35,
    'frequency_volume': 0.30,
  });
  await remoteConfig.fetchAndActivate();

  await dotenv.load();
  await SoLoud.instance.init();
  runApp(const NoisyApp());
}

class NoisyApp extends StatelessWidget {
  const NoisyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noisy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1C1C1C),
          surfaceContainerHighest: Color(0xFF252525),
          primary: Color(0xFFD4A017),
          onPrimary: Color(0xFF1C1C1C),
          secondary: Color(0xFFB8860B),
          onSecondary: Color(0xFF1C1C1C),
          onSurface: Color(0xFFE8E0D5),
          outline: Color(0xFF4A4440),
        ),
        scaffoldBackgroundColor: const Color(0xFF1C1C1C),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF252525),
          indicatorColor: const Color(0xFFD4A017).withValues(alpha: 0.2),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFD4A017));
            }
            return const IconThemeData(color: Color(0xFF7A7068));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFFD4A017),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Color(0xFF7A7068),
              fontSize: 12,
            );
          }),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF252525),
          foregroundColor: Color(0xFFE8E0D5),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFD4A017),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final ToneService _toneService;
  late final AudioEngine _audioEngine;
  late final JourneyEngine _journeyEngine;
  late final StorageService _storageService;
  late final MoodEngine _moodEngine;
  late final MotifEngine _motifEngine;
  late final AnalyticsService _analyticsService;
  final LlmService _llmService = LlmService();
  late final List<Widget> _screens;

  // Guards against re-entrant / mid-frame setState from engine notifications.
  bool _engineChangePending = false;

  // GlobalKey for LibraryScreen so we can call loadMixes() after a save.
  final _libraryKey = GlobalKey<LibraryScreenState>();
  final _mixerKey = GlobalKey<MixerScreenState>();

  static const List<String> _titles = ['Noisy', 'Mixer', 'Library', 'Journey'];

  @override
  void initState() {
    super.initState();
    _toneService = ToneService();
    _audioEngine = AudioEngine(_toneService);
    _audioEngine.addListener(_onEngineChanged);
    _journeyEngine = JourneyEngine();
    _storageService = StorageService();
    _moodEngine = MoodEngine();
    _motifEngine = MotifEngine();
    _analyticsService = AnalyticsService();

    _screens = [
      HomeScreen(
        audioEngine: _audioEngine,
        journeyEngine: _journeyEngine,
        moodEngine: _moodEngine,
        motifEngine: _motifEngine,
        llmService: _llmService,
        analyticsService: _analyticsService,
      ),
      MixerScreen(
        key: _mixerKey,
        engine: _audioEngine,
        journeyEngine: _journeyEngine,
        storage: _storageService,
        analyticsService: _analyticsService,
        // After a mix is saved from the Mixer, refresh the Library list.
        onMixSaved: () => _libraryKey.currentState?.loadMixes(),
      ),
      LibraryScreen(
        key: _libraryKey,
        engine: _audioEngine,
        storage: _storageService,
      ),
      JourneyScreen(
        audioEngine: _audioEngine,
        journeyEngine: _journeyEngine,
      ),
    ];
  }

  void _onEngineChanged() {
    // Rebuild so the app bar save button reflects current layer count.
    // Debounced via addPostFrameCallback to avoid mid-frame setState from
    // the engine's 50ms Timer ticks.
    if (!mounted || _engineChangePending) return;
    _engineChangePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engineChangePending = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _audioEngine.removeListener(_onEngineChanged);
    _audioEngine.dispose();
    _journeyEngine.dispose();
    _motifEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMixLayers = _audioEngine.layers.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ToneTestScreen()),
          ),
          child: Text(_titles[_selectedIndex]),
        ),
        actions: _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Save mix',
                  color: hasMixLayers
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  onPressed: hasMixLayers
                      ? () => _mixerKey.currentState?.openSaveDialog()
                      : null,
                ),
              ]
            : null,
      ),
      // IndexedStack keeps all screens alive so their state is preserved
      // across tab switches.
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          // Refresh the saved mixes list whenever the user switches to Library.
          if (index == 2 && _selectedIndex != 2) {
            _libraryKey.currentState?.loadMixes();
          }
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Mixer',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: 'Journey',
          ),
        ],
      ),
    );
  }
}
