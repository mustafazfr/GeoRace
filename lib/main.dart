import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geofinalapp/firebase_options.dart';
import 'package:geofinalapp/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geofinalapp/game_page.dart';
import 'package:geofinalapp/learn_page.dart';
import 'package:geofinalapp/login_page.dart';
import 'package:geofinalapp/main_page.dart';
import 'package:geofinalapp/profile_page.dart';
import 'package:geofinalapp/register_email_page.dart';
import 'package:geofinalapp/register_method_page.dart';
import 'package:geofinalapp/settings_page.dart';

void main() async {
  // Flutter binding'lerinin başlatıldığından emin ol
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase servisini başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase servisini başlat
  await Supabase.initialize(
    url:
        'https://bjjtsoqqhwgfolyoqkio.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqanRzb3FxaHdnZm9seW9xa2lvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MDY0MzIsImV4cCI6MjA2NTQ4MjQzMn0._EMyjl51Z4ZuIQ6X6qRZHHBjxKv0FZ93P_Sz556izYg',
  );

  // Uygulamayı, tema durumunu yöneten Provider ile sarmalayarak çalıştır
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

// Supabase client'ına kolay erişim için helper
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget'ı ile ThemeNotifier'daki değişiklikleri dinle
    return Consumer<ThemeNotifier>(
      builder: (context, theme, child) {
        return MaterialApp(
          title: 'Bayrak Yarışı',
          debugShowCheckedModeBanner: false, // Debug etiketini kaldırır
          // Tema Ayarları
          theme: ThemeData.light(useMaterial3: true), // Açık tema
          darkTheme: ThemeData.dark(useMaterial3: true), // Koyu tema
          themeMode:
              theme.darkTheme
                  ? ThemeMode.dark
                  : ThemeMode.light, // Hangi temanın aktif olacağını belirle
          // Rota Ayarları
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginPage(),
            '/main': (context) => const MainPage(),
            '/game': (context) => const GamePage(),
            '/learn': (context) => const LearnPage(),
            '/profile': (context) => const ProfilePage(),
            '/settings': (context) => const SettingsPage(),
            '/registerMethod': (context) => const RegisterMethodPage(),
            '/registerEmail': (context) => const RegisterEmailPage(),
          },
        );
      },
    );
  }
}
