import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from `.env` if present. Don't crash the app
  // when the file is missing or malformed — just log and continue so the
  // splash screen won't block forever.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e, st) {
    debugPrint('Warning: failed to load .env: $e\n$st');
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Fallback or error logging if firebase fails to init (e.g. missing keys)
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const ProviderScope(child: FursalApp()));
}

class FursalApp extends ConsumerWidget {
  const FursalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SajiloKhel',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
