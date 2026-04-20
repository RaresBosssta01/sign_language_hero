import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Aici ținem minte ce a bifat utilizatorul
  String tipCont = 'Utilizator'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Creează Cont"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Cine ești?", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Bifa pentru tipul de cont
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Am nevoie de ajutor"),
                  selected: tipCont == 'Utilizator',
                  onSelected: (bool selected) {
                    setState(() { tipCont = 'Utilizator'; });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Sunt Voluntar"),
                  selected: tipCont == 'Voluntar',
                  onSelected: (bool selected) {
                    setState(() { tipCont = 'Voluntar'; });
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            const TextField(decoration: InputDecoration(labelText: "Nume Complet", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const TextField(decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const TextField(obscureText: true, decoration: InputDecoration(labelText: "Parolă", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: () {
                print("Creare cont: $tipCont");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                tipCont == 'Voluntar' ? "ÎNSCRIE-TE CA VOLUNTAR" : "CREEAZĂ CONT", 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              ),
            ),
          ],
        ),
      ),
    );
  }
}