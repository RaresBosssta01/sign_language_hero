import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screen/login_screen.dart';

void main() async {
  // 1. Pornim motorul Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Facem conexiunea cu baza de date
  await Supabase.initialize(
    url: 'https://nmjksiotpkvwzlhemuzr.supabase.co',
    anonKey: 'sb_publishable_RwktDbQbp0RKUTEyAA0AQQ_b-eZNrkD',
  );

  runApp(const SignLanguageApp());
}

class SignLanguageApp extends StatelessWidget {
  const SignLanguageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sign Language Hero',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007BFF)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}