import 'package:flutter/material.dart';
// Importăm ecranul cu camera (Oglinda), presupunând că e în același folder (screens)
import 'mirror_screen.dart'; 

// --------------------------------------------------------
// ECRANUL DICȚIONAR (Stil TikTok / Reels)
// --------------------------------------------------------
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  // Baza de date locală cu semnele pe care le învățăm
  final List<Map<String, dynamic>> _semne = [
    {
      'titlu': 'Urgență / Ajutor',
      'categorie': 'Medical',
      'gifUrl': '', // Lăsăm gol deocamdată, am făcut un design frumos de înlocuire
      'aiTip': 'Loviturile scurte pe piept cu pumnul înseamnă urgență. Păstrează contactul vizual intens pentru a transmite gravitatea situației.',
      'dificultate': 'Ușor',
    },
    {
      'titlu': 'Sunt aici pentru tine',
      'categorie': 'Empatie',
      'gifUrl': '', 
      'aiTip': 'Mișcarea ambelor mâini deschise spre piept semnifică deschiderea. Expresia facială trebuie să fie blândă, ușor zâmbitoare.',
      'dificultate': 'Mediu',
    },
    {
      'titlu': 'Unde te doare?',
      'categorie': 'Medical',
      'gifUrl': '', 
      'aiTip': 'Folosește degetul arătător pentru a indica zona, combinat cu sprâncenele ușor coborâte, care în LSR marchează o întrebare (cine/ce/unde).',
      'dificultate': 'Greu',
    },
    {
      'titlu': 'Am chemat ambulanța',
      'categorie': 'Acțiune',
      'gifUrl': '', 
      'aiTip': 'Semnul pentru "mașină" combinat cu semnul crucii. Fă mișcările hotărât pentru a transmite siguranță și calm.',
      'dificultate': 'Mediu',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundal negru specific playerelor video
      
      // Bara de sus (Transparentă ca să se vadă "video-ul" pe sub ea)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Învață LSR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true, 
      
      // Motorul care face "Swipe Up" (Derulare verticală pe tot ecranul)
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _semne.length,
        itemBuilder: (context, index) {
          return _buildVideoCard(_semne[index]);
        },
      ),
    );
  }

  // --- COMPONENTA VIZUALĂ PENTRU FIECARE SEMN ---
  Widget _buildVideoCard(Map<String, dynamic> semn) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. ZONA VIDEO (Fundalul ecranului)
        // La hackathon, dacă nu aveți un GIF real pus la 'gifUrl', va apărea acest ecran superb de "Placeholder"
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade900, Colors.black],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 60, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Text(
                  "Videoclip demonstrativ pentru\n« ${semn['titlu']} »",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                )
              ],
            ),
          ),
        ),

        // Gradient negru în partea de jos pentru a putea citi textul peste "video"
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [Colors.black.withOpacity(0.95), Colors.transparent],
            ),
          ),
        ),

        // 2. INFORMAȚIILE ȘI BUTOANELE (Partea de jos a ecranului)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Eticheta Categoriei (ex: Medical)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.teal.shade700, borderRadius: BorderRadius.circular(20)),
                      child: Text(semn['categorie'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text("Nivel: ${semn['dificultate']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Titlul Semnului
                Text(semn['titlu'], style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
                const SizedBox(height: 20),

                // Cardul "AI Co-Pilot" (Sfatul)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.tealAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Analiză AI", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text(semn['aiTip'], style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Butonul "Camera / Încearcă Tu" care deschide ecranul Oglindă
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Legătura magică către camera frontală!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MirrorScreen(
                            numeSemn: semn['titlu'],
                            sfatAI: semn['aiTip'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_front_rounded, color: Colors.teal),
                    label: const Text("ANTRENEAZĂ-TE ÎN OGLINDĂ", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Spațiu la bază
              ],
            ),
          ),
        ),
      ],
    );
  }
}