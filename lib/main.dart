import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/reminder_engine.dart';
import 'core/storage_manager.dart';
import 'providers/app_state_provider.dart';
import 'screens/new_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize core services (only on mobile platforms)
  if (Platform.isAndroid || Platform.isIOS) {
    final reminderEngine = ReminderEngine();
    await reminderEngine.initialize();
    await reminderEngine.requestPermissions();
  }

  // Initialize storage
  final storage = StorageManager();
  await storage.database; // Ensure database is created

  runApp(const KnopApp());
}

class KnopApp extends StatelessWidget {
  const KnopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Knop Flashcard',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF87CEEB), // Sky blue
                brightness: Brightness.light,
                primary: const Color(0xFF87CEEB),
                secondary: const Color(0xFFB0E0E6),
                surface: Colors.white,
                background: const Color(0xFFF0F8FF), // Alice blue
              ),
              scaffoldBackgroundColor: const Color(0xFFF0F8FF),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            themeMode:
                appState.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const NewHomeScreen(),
          );
        },
      ),
    );
  }
}
