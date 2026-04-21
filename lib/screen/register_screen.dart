import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String tipCont = 'Utilizator'; 
  String? nivelLSR = 'Incepator'; 
  final List<String> optiuniLSR = ['Incepator', 'Mediu', 'Fluent', 'CODA', 'Certificat'];
  
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color backgroundBlue = Color(0xFFE3F2FD);

    InputDecoration inputStyle(String hint, IconData icon) {
      return InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      );
    }

    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        title: const Text("Alătură-te Misiunii", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: primaryBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Form( // AM ADĂUGAT FORMULARUL
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Alege-ți calea ✨", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87), textAlign: TextAlign.center),
                  const SizedBox(height: 25),
                  
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () { setState(() { tipCont = 'Utilizator'; }); },
                          child: _buildRoleCard(icon: "✋", title: "Am nevoie\nde ajutor", isSelected: tipCont == 'Utilizator', primaryColor: primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () { setState(() { tipCont = 'Voluntar'; }); },
                          child: _buildRoleCard(icon: "💙", title: "Sunt\nVoluntar", isSelected: tipCont == 'Voluntar', primaryColor: const Color(0xFF43A047)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tipCont == 'Voluntar') ...[
                          const Text("Super! Care e super-puterea ta în LSR? 💪", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: nivelLSR,
                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: primaryBlue),
                            decoration: inputStyle("Nivel LSR", Icons.bar_chart_rounded),
                            borderRadius: BorderRadius.circular(20),
                            items: optiuniLSR.map((String valoare) {
                              return DropdownMenuItem<String>(value: valoare, child: Text(valoare, style: const TextStyle(fontSize: 16)));
                            }).toList(),
                            onChanged: (String? nouaValoare) { setState(() { nivelLSR = nouaValoare; }); },
                          ),
                          const SizedBox(height: 25),
                          const Divider(),
                          const SizedBox(height: 15),
                        ],

                        const Text("Datele de identificare", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 15),
                        
                        // CAMP NUME 
                        TextFormField(
                          decoration: inputStyle("Numele tău complet", Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nu poți fi un erou anonim!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        // CAMP EMAIL
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: inputStyle("Adresa de email validă", Icons.alternate_email),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email-ul este obligatoriu.';
                            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                              return 'Format de email invalid.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        // CAMP PAROLA COMPLEXA
                        TextFormField(
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: "O parolă puternică",
                            prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                              onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Parola este obligatorie.';
                            if (value.length < 8) return 'Minim 8 caractere.';
                            // Verifica daca exista cel putin o litera mare si o cifra
                            if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Trebuie să conțină o majusculă.';
                            if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) return 'Trebuie să conțină o cifră.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              // VERIFICAREA FINALA A INTREGULUI FORMULAR
                              if (_formKey.currentState!.validate()) {
                                print("Formular PERFECT validat! Creare cont: $tipCont");
                              } else {
                                print("Sunt erori in formular!");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tipCont == 'Voluntar' ? const Color(0xFF43A047) : primaryBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                              tipCont == 'Voluntar' ? "DEVII EROU ACUM! 💥" : "CREEAZĂ CONT! 🎉", 
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () { Navigator.pop(context); },
                    child: RichText(
                      text: const TextSpan(
                        text: "Ai deja cont? ", style: TextStyle(color: Colors.black54, fontSize: 16),
                        children: [TextSpan(text: "Autentifică-te!", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold))],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String icon, required String title, required bool isSelected, required Color primaryColor}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isSelected ? primaryColor : Colors.white, width: 3),
        boxShadow: [BoxShadow(color: isSelected ? primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.05), blurRadius: isSelected ? 15 : 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 45)),
          const SizedBox(height: 15),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? primaryColor : Colors.black87)),
          const SizedBox(height: 10),
          Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? primaryColor : Colors.grey.shade300),
        ],
      ),
    );
  }
}