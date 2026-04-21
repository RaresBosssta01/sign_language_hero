import 'package:flutter/material.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Cheia secreta pentru a verifica formularul
  final _formKey = GlobalKey<FormState>();
  
  // Variabila pentru a arata/ascunde parola
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form( // AM ADĂUGAT FORMULARUL AICI
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: const Text("🦸‍♂️", style: TextStyle(fontSize: 60)),
                    ),
                    const SizedBox(height: 30),
                    
                    const Text("Bine ai revenit!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E88E5), letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    const Text("Comunitatea avea nevoie de tine.", style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 40),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          // CAMP EMAIL VALIDAT
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "Adresa de email",
                              prefixIcon: const Icon(Icons.alternate_email, color: Colors.blueAccent),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Te rog introdu un email.';
                              }
                              // Verificare simpla daca contine @ si .
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Te rog introdu un email valid.';
                              }
                              return null; // Daca e null, totul e corect!
                            },
                          ),
                          const SizedBox(height: 15),
                          
                          // CAMP PAROLA VALIDAT CU BUTON DE VIZUALIZARE
                          TextFormField(
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: "Parola secreta",
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() { _isPasswordVisible = !_isPasswordVisible; });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Te rog introdu parola.';
                              }
                              if (value.length < 6) {
                                return 'Parola trebuie să aibă minim 6 caractere.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                // AICI DECLANȘĂM VERIFICĂRILE
                                if (_formKey.currentState!.validate()) {
                                  print("LOGARE CU SUCCES!");
                                  // Aici va veni codul de trecere la pagina principala
                                } else {
                                  print("Eroare la completare.");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text("INTRĂ ÎN ACȚIUNE 🚀", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Ești la prima misiune? ",
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                          children: [TextSpan(text: "Fă-ți cont!", style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold))],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}