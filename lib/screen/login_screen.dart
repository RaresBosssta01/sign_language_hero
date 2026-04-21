import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Cheia pentru validarea formularului
  final _formKey = GlobalKey<FormState>();
  
  // "Microfoanele" care ascultă ce scrie utilizatorul
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Variabila pentru ascunderea/afișarea parolei
  bool _isPasswordVisible = false;

  // Curățăm memoria la închiderea ecranului (Best Practice)
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), 
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- ICONIȚA GAMIFICATĂ ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2), 
                            blurRadius: 20, 
                            offset: const Offset(0, 10)
                          ),
                        ],
                      ),
                      child: const Text("🦸‍♂️", style: TextStyle(fontSize: 60)),
                    ),
                    const SizedBox(height: 30),
                    
                    // --- TEXTE DE BUN VENIT ---
                    const Text(
                      "Bine ai revenit!", 
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E88E5), letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Comunitatea avea nevoie de tine.", 
                      style: TextStyle(fontSize: 16, color: Colors.black54)
                    ),
                    const SizedBox(height: 40),
                    
                    // --- FORMULARUL DE LOGIN ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05), 
                            blurRadius: 15, 
                            offset: const Offset(0, 5)
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          
                          // CÂMP EMAIL
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "Adresa de email",
                              prefixIcon: const Icon(Icons.alternate_email, color: Colors.blueAccent),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Te rog introdu un email.';
                              if (!value.contains('@') || !value.contains('.')) return 'Te rog introdu un email valid.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          
                          // CÂMP PAROLĂ
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: "Parola secreta",
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Te rog introdu parola.';
                              if (value.length < 6) return 'Parola trebuie să aibă minim 6 caractere.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),
                          
                          // BUTON DE LOGIN
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () async {
                                // 1. Verificăm dacă formatul e corect (nu e gol, are @ etc.)
                                if (_formKey.currentState!.validate()) {
                                  
                                  // 2. Deschidem "baza de date" locală a telefonului
                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                  
                                  // Citim ce a fost salvat la Register
                                  String? emailSalvat = prefs.getString('email_salvat');
                                  String? parolaSalvata = prefs.getString('parola_salvata');

                                  // 3. Verificăm credențialele
                                  bool esteContInregistrat = (_emailController.text == emailSalvat && _passwordController.text == parolaSalvata);
                                  bool esteContDemo = (_emailController.text == "erou@test.ro" && _passwordController.text == "Erou123!");

                                  // Dacă se potrivesc...
                                  if (esteContInregistrat || esteContDemo) {
                                    if(context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                                      );
                                    }
                                  } else {
                                    // Dacă nu există în memorie...
                                    if(context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Email sau parolă incorecte! Sau contul nu există."),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text(
                                "INTRĂ ÎN ACȚIUNE 🚀", 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- LINK CĂTRE REGISTER ---
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Ești la prima misiune? ",
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                          children: [
                            TextSpan(
                              text: "Fă-ți cont!", 
                              style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)
                            )
                          ],
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