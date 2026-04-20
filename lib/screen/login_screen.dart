import 'package:flutter/material.dart';
import 'package:sign_language_hero/screen/lib/screens/register_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Inimioara care ține loc de logo momentan
              const Icon(Icons.favorite, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              
              const Text(
                "Sign Language Hero", 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueAccent)
              ),
              const SizedBox(height: 40),
              
              // Câmp de Email
              const TextField(
                decoration: InputDecoration(
                  labelText: "Email", 
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              
              // Câmp de Parolă
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Parolă", 
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              
              // Buton de Login
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Aici facem navigarea către pagina de Register
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  "Nu ai cont? Înscrie-te acum", 
                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}