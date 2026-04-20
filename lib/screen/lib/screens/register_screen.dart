import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String tipCont = 'Utilizator'; 
  
  // Variabila pentru nivelul LSR (valoarea initiala)
  String? nivelLSR = 'Incepator'; 

  // Lista de optiuni pentru dropdown
  final List<String> optiuniLSR = ['Incepator', 'Mediu', 'Fluent', 'CODA', 'Certificat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Creează Cont"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Adaugat pentru a evita erori de spatiu pe ecrane mici
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Cine ești?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Am nevoie de ajutor"),
                    selected: tipCont == 'Utilizator',
                    onSelected: (bool selected) { setState(() { tipCont = 'Utilizator'; }); },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Sunt Voluntar"),
                    selected: tipCont == 'Voluntar',
                    onSelected: (bool selected) { setState(() { tipCont = 'Voluntar'; }); },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- LOGICA CONDITIONALA ---
              // Daca tipCont este 'Voluntar', aratam Dropdown-ul
              if (tipCont == 'Voluntar') ...[
                const Text("Care este nivelul tău de LSR?", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: nivelLSR,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: optiuniLSR.map((String valoare) {
                    return DropdownMenuItem<String>(
                      value: valoare,
                      child: Text(valoare),
                    );
                  }).toList(),
                  onChanged: (String? nouaValoare) {
                    setState(() { nivelLSR = nouaValoare; });
                  },
                ),
                const SizedBox(height: 20),
              ],
              // --- SFARSIT LOGICA ---

              const TextField(decoration: InputDecoration(labelText: "Nume Complet", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              const TextField(decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              const TextField(obscureText: true, decoration: InputDecoration(labelText: "Parolă", border: OutlineInputBorder())),
              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: () {
                  print("Cont nou: $tipCont | Nivel LSR: ${tipCont == 'Voluntar' ? nivelLSR : 'N/A'}");
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: Text(tipCont == 'Voluntar' ? "ÎNSCRIE-TE CA VOLUNTAR" : "CREEAZĂ CONT", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}