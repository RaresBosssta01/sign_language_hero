import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Implicit selectam 'Utilizator'
  String tipCont = 'Utilizator'; 
  
  String? nivelLSR = 'Incepator'; 
  final List<String> optiuniLSR = ['Incepator', 'Mediu', 'Fluent', 'CODA', 'Certificat'];

  @override
  Widget build(BuildContext context) {
    // Paleta de culori consistenta cu Login
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color backgroundBlue = Color(0xFFE3F2FD);

    // Stil comun pentru campurile de input (bule gri, rotunjite)
    InputDecoration inputStyle(String hint, IconData icon) {
      return InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      );
    }

    return Scaffold(
      backgroundColor: backgroundBlue,
      // AppBar customizat, mai prietenos
      appBar: AppBar(
        title: const Text(
          "Alătură-te Misiunii", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: primaryBlue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Alege-ți calea ✨", 
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                
                // --- SELECȚIE ROLURI GAMIFICATĂ (Carduri mari) ---
                Row(
                  children: [
                    // Card Utilizator
                    Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() { tipCont = 'Utilizator'; }); },
                        child: _buildRoleCard(
                          icon: "✋", 
                          title: "Am nevoie\nde ajutor", 
                          isSelected: tipCont == 'Utilizator',
                          primaryColor: primaryBlue
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Card Voluntar
                    Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() { tipCont = 'Voluntar'; }); },
                        child: _buildRoleCard(
                          icon: "💙", 
                          title: "Sunt\nVoluntar", 
                          isSelected: tipCont == 'Voluntar',
                          primaryColor: const Color(0xFF43A047) // Un verde pentru voluntari
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),

                // --- FORMULARUL DE ÎNSCRIERE (Card alb, rotunjit) ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // --- LOGICA CONDITIONALA PENTRU VOLUNTARI ---
                      if (tipCont == 'Voluntar') ...[
                        const Text(
                          "Super! Care e super-puterea ta în LSR? 💪", 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        // Dropdown stilizat ca input field
                        DropdownButtonFormField<String>(
                          value: nivelLSR,
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: primaryBlue),
                          decoration: inputStyle("Nivel LSR", Icons.bar_chart_rounded),
                          borderRadius: BorderRadius.circular(20),
                          items: optiuniLSR.map((String valoare) {
                            return DropdownMenuItem<String>(
                              value: valoare,
                              child: Text(valoare, style: const TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                          onChanged: (String? nouaValoare) {
                            setState(() { nivelLSR = nouaValoare; });
                          },
                        ),
                        const SizedBox(height: 25),
                        const Divider(),
                        const SizedBox(height: 15),
                      ],
                      // --- SFARSIT LOGICA ---

                      const Text(
                        "Datele de identificare", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 15),
                      TextField(decoration: inputStyle("Numele tău complet (ex: Erou Ion)", Icons.person_outline)),
                      const SizedBox(height: 15),
                      TextField(decoration: inputStyle("Adresa de email validă", Icons.alternate_email)),
                      const SizedBox(height: 15),
                      TextField(obscureText: true, decoration: inputStyle("O parolă puternică", Icons.lock_outline)),
                      const SizedBox(height: 30),
                      
                      // Buton Gamificat de Finalizare
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            print("Creare cont: $tipCont | Nivel LSR: $nivelLSR");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tipCont == 'Voluntar' ? const Color(0xFF43A047) : primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            tipCont == 'Voluntar' ? "DEVII EROU ACUM! 💥" : "CREEAZĂ CONT! 🎉", 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Link înapoi la Login
                TextButton(
                  onPressed: () { Navigator.pop(context); },
                  child: RichText(
                    text: const TextSpan(
                      text: "Ai deja cont? ",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                      children: [
                        TextSpan(
                          text: "Autentifică-te!",
                          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER PENTRU CARDURILE DE ROL ---
  Widget _buildRoleCard({
    required String icon, 
    required String title, 
    required bool isSelected,
    required Color primaryColor
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.white, 
          width: 3
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 15 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 45)),
          const SizedBox(height: 15),
          Text(
            title, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: isSelected ? primaryColor : Colors.black87
            ),
          ),
          const SizedBox(height: 10),
          // Bifa vizuala
          Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked, 
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}