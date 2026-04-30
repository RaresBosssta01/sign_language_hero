import 'package:flutter/material.dart';
// Importăm ecranul cu camera (Oglinda)
import 'mirror_screen.dart'; 

// --------------------------------------------------------
// ECRANUL DICȚIONAR (Stil TikTok + Mod Căutare)
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
      'gifUrl': '', 
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
      'aiTip': 'Folosește degetul arătător pentru a indica zona, combinat cu sprâncenele ușor coborâte, care în LSR marchează o întrebare.',
      'dificultate': 'Greu',
    },
    {
      'titlu': 'Am chemat ambulanța',
      'categorie': 'Acțiune',
      'gifUrl': '', 
      'aiTip': 'Semnul pentru "mașină" combinat cu semnul crucii. Fă mișcările hotărât pentru a transmite siguranță și calm.',
      'dificultate': 'Mediu',
    },
    {
      'titlu': 'Poliție',
      'categorie': 'Urgență',
      'gifUrl': '', 
      'aiTip': 'Formează litera "C" cu mâna (semnificând insigna/cascheta) și plasează-o pe piept în partea stângă.',
      'dificultate': 'Ușor',
    },
    {
      'titlu': 'Mulțumesc',
      'categorie': 'Politețe',
      'gifUrl': '', 
      'aiTip': 'Du degetele de la o mână spre buze, apoi mișcă mâna înainte, spre persoana căreia îi mulțumești.',
      'dificultate': 'Ușor',
    }
  ];

  // Controlerul pentru scroll-ul vertical (Reels)
  late PageController _pageController;
  
  // Starea pentru căutare
  bool _isSearchMode = false;
  List<Map<String, dynamic>> _semneFiltrate = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _semneFiltrate = List.from(_semne); // Inițial, afișăm toate semnele
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Funcție de filtrare live
  void _filtreazaSemne(String query) {
    setState(() {
      if (query.isEmpty) {
        _semneFiltrate = List.from(_semne);
      } else {
        _semneFiltrate = _semne.where((semn) => 
          semn['titlu'].toString().toLowerCase().contains(query.toLowerCase()) ||
          semn['categorie'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  // Funcție care te duce la videoclipul selectat din căutare
  void _mergiLaSemn(Map<String, dynamic> semnSelectat) {
    int index = _semne.indexOf(semnSelectat);
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
      _semneFiltrate = List.from(_semne);
    });
    // Sărim direct la videoclipul corect în Feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      
      appBar: AppBar(
        backgroundColor: _isSearchMode ? const Color(0xFF111827) : Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (_isSearchMode) {
              setState(() => _isSearchMode = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isSearchMode ? "Caută Semn" : "Învață LSR", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchController.clear();
                  _semneFiltrate = List.from(_semne);
                }
              });
            },
          )
        ],
      ),
      extendBodyBehindAppBar: !_isSearchMode, 
      
      body: _isSearchMode ? _buildSearchGrid() : _buildFeedMode(),
    );
  }

  // --- MODUL 1: FEED TIKTOK / REELS ---
  Widget _buildFeedMode() {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _semne.length,
      itemBuilder: (context, index) {
        return _buildVideoCard(_semne[index]);
      },
    );
  }

  // --- MODUL 2: CĂUTARE (Când ai nevoie rapid de un cuvânt) ---
  Widget _buildSearchGrid() {
    return Column(
      children: [
        // Bara de căutare text
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filtreazaSemne,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Ex: Urgență, Ambulanță, Apă...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        
        // Grila de rezultate
        Expanded(
          child: _semneFiltrate.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 15),
                    const Text("Nu am găsit niciun semn.", style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _semneFiltrate.length,
                itemBuilder: (context, index) {
                  final s = _semneFiltrate[index];
                  return GestureDetector(
                    onTap: () => _mergiLaSemn(s),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.teal.shade900, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.play_circle_fill_rounded, color: Colors.tealAccent),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['titlu'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("${s['categorie']} • Nivel: ${s['dificultate']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white54),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  // --- COMPONENTA VIZUALĂ PENTRU FIECARE SEMN (Tiktok Card) ---
  Widget _buildVideoCard(Map<String, dynamic> semn) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. ZONA VIDEO (Fundalul ecranului)
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
                    color: Colors.white.withValues(alpha: 0.1),
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

        // Gradient negru în partea de jos pentru a putea citi textul
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [Colors.black.withValues(alpha: 0.95), Colors.transparent],
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3), width: 1),
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
                  child: ElevatedButton(
                    onPressed: () {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_front_rounded, color: Colors.teal),
                        const SizedBox(width: 10),
                        const Text("ANTRENEAZĂ-TE ÎN OGLINDĂ", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Text("+10 XP", style: TextStyle(color: Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ),
                ),
                const SizedBox(height: 10), 
              ],
            ),
          ),
        ),
      ],
    );
  }
}