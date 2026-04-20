import 'package:flutter/material.dart';
import 'screen/login_screen.dart'; // Aici am pus "screen" în loc de "screens"

void main() {
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
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Aici îi spunem să pornească direct cu Login
    );
  }
}