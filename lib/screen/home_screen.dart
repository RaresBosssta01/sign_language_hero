import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dictionary_screen.dart';

// Importăm celelalte ecrane pentru a putea naviga către ele
import 'settings_screen.dart';
import 'community_screen.dart';

// --------------------------------------------------------
// 1. CLASA VOLUNTAR (Logica de mișcare)
// --------------------------------------------------------
class Voluntar {
  final String nume;
  final String specializare;
  final double rating;
  
  LatLng pozitie;
  LatLng? destinatie; 
  bool inMiscare;

  Voluntar({
    required this.nume,
    required this.specializare,
    required this.rating,
    required this.pozitie,
    this.destinatie,
    this.inMiscare = false,
  });

  void faUnPas() {
    if (!inMiscare || destinatie == null) return;

    double dLat = destinatie!.latitude - pozitie.latitude;
    double dLng = destinatie!.longitude - pozitie.longitude;
    double distanta = sqrt(dLat * dLat + dLng * dLng);
    
    // Viteza de mers pe jos
    double lungimePas = 0.000015;

    if (distanta < lungimePas) {
      pozitie = destinatie!;
      inMiscare = false;
    } else {
      pozitie = LatLng(
        pozitie.latitude + (dLat / distanta) * lungimePas,
        pozitie.longitude + (dLng / distanta) * lungimePas,
      );
    }
  }
}

// --------------------------------------------------------
// 2. ECRANUL PRINCIPAL
// --------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final LatLng _myLocation = const LatLng(44.4268, 26.1025);

  // Motorul de animație
  late List<Voluntar> voluntari;
  Timer? _motorTimp;

  @override
  void initState() {
    super.initState();
    _genereazaVoluntari();
    _pornesteMotorulTimpului();
  }

  void _genereazaVoluntari() {
    voluntari = [
      Voluntar(
        nume: "Andrei",
        specializare: "Interpret Fluent",
        rating: 4.9,
        pozitie: const LatLng(44.4300, 26.0950),
        destinatie: const LatLng(44.4270, 26.1010), // Se îndreaptă spre tine
        inMiscare: true,
      ),
      Voluntar(
        nume: "Maria",
        specializare: "CODA",
        rating: 5.0,
        pozitie: const LatLng(44.4220, 26.1100),
      ),
      Voluntar(
        nume: "Ion",
        specializare: "Nivel Mediu",
        rating: 4.5,
        pozitie: const LatLng(44.4350, 26.1050),
        destinatie: const LatLng(44.4380, 26.0980),
        inMiscare: true,
      ),
    ];
  }

  void _pornesteMotorulTimpului() {
    _motorTimp = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        for (var v in voluntari) {
          v.faUnPas();
        }
      });
    });
  }

  @override
  void dispose() {
    _motorTimp?.cancel(); // Oprim timer-ul ca să nu consume baterie
    super.dispose();
  }

  // Pop-up-ul cu Profilul Voluntarului
  void _arataProfil(Voluntar v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: v.inMiscare ? Colors.orange.shade100 : Colors.green.shade100,
                  child: Icon(Icons.person, size: 35, color: v.inMiscare ? Colors.orange : Colors.green),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.nume, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(v.specializare, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 5),
                Text("${v.rating} Scor Încredere", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: v.inMiscare ? Colors.orange.shade50 : Colors.green.shade50, 
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(
                    v.inMiscare ? "În Mișcare 🚶" : "Disponibil ✅", 
                    style: TextStyle(color: v.inMiscare ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)
                  ),
                )
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.video_call, color: Colors.white),
                label: const Text("CERE AJUTOR VIDEO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Apel trimis către ${v.nume}...")),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combinăm markerul tău cu lista de voluntari
    List<Marker> mapMarkers = [
      Marker(
        point: _myLocation,
        width: 60, height: 60,
        child: const Icon(Icons.person_pin_circle_rounded, color: Colors.red, size: 50),
      ),
    ];

    // Adăugăm voluntarii animati în listă
    mapMarkers.addAll(voluntari.map((v) {
      return Marker(
        point: v.pozitie,
        width: 80, height: 80,
        child: GestureDetector(
          onTap: () => _arataProfil(v),
          child: _buildDynamicMarker(v),
        ),
      );
    }));

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true, 
      
      // --- BARA DE SUS (AppBar) ---
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1E88E5),
              child: Text("🦸‍♂️", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Erou Nivelul 3", style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text("450 XP", style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 32),
            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
          ),
          const SizedBox(width: 10),
        ],
      ),

      endDrawer: _buildDrawerMenu(),

      // --- CORPUL PAGINII ---
      body: Stack(
        children: [
          // 1. Harta
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _myLocation,
                initialZoom: 14.5,
                minZoom: 5.0,
                maxZoom: 19.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.signlanguagehero.app',
                  maxNativeZoom: 18,
                  keepBuffer: 3,
                ),
                MarkerLayer(markers: mapMarkers),
              ],
            ),
          ),

          // 2. Butonul Recentrare
          Positioned(
            bottom: 220, right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () => _mapController.move(_myLocation, 14.5),
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF1E88E5)),
            ),
          ),

          // 3. Panoul SOS 
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Voluntari în zonă: 3", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 10),
                            SizedBox(width: 5),
                            Text("Andrei e la 2 min", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onLongPress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("🚨 Cerere de urgență trimisă voluntarilor!"), backgroundColor: Colors.redAccent),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFEF5350)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
                              SizedBox(width: 10),
                              Text("APEL VIDEO URGENT", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text("Ține apăsat 2 secunde", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MENIUL LATERAL ---
  Widget _buildDrawerMenu() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Text("🦸‍♂️", style: TextStyle(fontSize: 40))),
                const SizedBox(height: 15),
                const Text("Rareș (Erou)", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(value: 0.45, backgroundColor: Colors.white24, color: Colors.amber.shade400, minHeight: 8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text("Nivel 3", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(Icons.map_rounded, "Harta Urgențelor", "Vezi voluntarii activi"),
                ListTile(
                  leading: const Icon(Icons.forum_rounded, color: Color(0xFF1E88E5), size: 28),
                  title: const Text("Comunitate & Feed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text("Forum, discuții, sfaturi"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                    child: const Text("3 Noi", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()));
                  },
                ),
                _buildMenuItem(Icons.calendar_month_rounded, "Programări", "Rezervă un interpret pt. mâine"),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E88E5), size: 28),
                  title: const Text("Dicționar LSR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text("Învață semne noi zilnic"),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context); // Închide meniul lateral
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DictionaryScreen()));
                  },
                ),
                const Divider(height: 30),
                ListTile(
                  leading: Icon(Icons.settings_rounded, color: Colors.grey.shade700, size: 28),
                  title: const Text("Setări", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text("Cont, notificări, intimitate"),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); 
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text("Deconectare", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- HELPERS (Design personalizat pentru Markere) ---
  Widget _buildMenuItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E88E5), size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () {},
    );
  }

  // Metoda care construiește design-ul markerului în funcție de starea voluntarului (se mișcă sau nu)
  Widget _buildDynamicMarker(Voluntar v) {
    Color ringColor = v.inMiscare ? Colors.orange : Colors.green;
    Color bgColor = v.inMiscare ? Colors.orange.shade50 : Colors.green.shade50;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: ringColor, width: 3),
          ),
          child: CircleAvatar(
            radius: 18, 
            backgroundColor: bgColor,
            child: Text(v.nume[0], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ringColor)),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
          child: Text("${v.nume} • ${v.rating}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        )
      ],
    );
  }
}