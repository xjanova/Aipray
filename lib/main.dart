import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/update_service.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';

final storageService = StorageService();
final syncService = SyncService();
final updateService = UpdateService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0D),
  ));

  await storageService.init();
  syncService.init();

  runApp(const AiprayApp());
}

class AiprayApp extends StatelessWidget {
  const AiprayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSeenOnboarding =
        storageService.getSetting<bool>('seen_onboarding') ?? false;

    return MaterialApp(
      title: 'Aipray - สวดมนต์อัจฉริยะ',
      debugShowCheckedModeBanner: false,
      theme: AiprayTheme.darkTheme,
      home: hasSeenOnboarding ? const MainShell() : const OnboardingScreen(),
    );
  }
}
