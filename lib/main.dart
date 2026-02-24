import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/journey_screen.dart';
import 'screens/library_screen.dart';
import 'screens/mixer_screen.dart';
import 'services/audio_engine.dart';
import 'services/journey_engine.dart';

void main() {
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
  late final AudioEngine _audioEngine;
  late final JourneyEngine _journeyEngine;
  late final List<Widget> _screens;

  static const List<String> _titles = ['Noisy', 'Mixer', 'Library', 'Journey'];

  @override
  void initState() {
    super.initState();
    _audioEngine = AudioEngine();
    _journeyEngine = JourneyEngine();
    _screens = [
      HomeScreen(audioEngine: _audioEngine, journeyEngine: _journeyEngine),
      MixerScreen(engine: _audioEngine),
      LibraryScreen(engine: _audioEngine),
      JourneyScreen(
          audioEngine: _audioEngine, journeyEngine: _journeyEngine),
    ];
  }

  @override
  void dispose() {
    _audioEngine.dispose();
    _journeyEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
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

