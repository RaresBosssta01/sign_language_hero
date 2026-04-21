import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // "Telecomanda" hartii - ne permite sa o controlam din butoane
  final MapController _mapController = MapController();

  // Coordonata ta (Centrul Bucurestiului)
  final LatLng _myLocation = const LatLng(44.4268, 26.1025);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true, 
      
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
            onPressed: () {
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      endDrawer: _buildDrawerMenu(),

      // --- HARTA FULL SCREEN (Optimizată Anti-Lag) ---
      body: Stack(
        children: [
          // 1. Positioned.fill FORȚEAZĂ harta să se lipească de toate marginile ecranului
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _myLocation,
                initialZoom: 14.5,
                minZoom: 3.0, // Zoom out global deblocat
                maxZoom: 18.0, 
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all, 
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.signlanguagehero.app',
                  // MAGIC TRICK: Pre-încarcă harta în fundal pentru glisări fine
                  keepBuffer: 3, 
                ),
                MarkerLayer(
                  markers: [
                    // Markerul tău
                    Marker(
                      point: _myLocation,
                      width: 60, height: 60,
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.red, size: 50),
                    ),
                    // Voluntarii
                    Marker(point: const LatLng(44.4300, 26.0950), width: 80, height: 80, child: _buildMapMarker("Andrei", "Fluent", true)),
                    Marker(point: const LatLng(44.4220, 26.1100), width: 80, height: 80, child: _buildMapMarker("Maria", "CODA", true)),
                    Marker(point: const LatLng(44.4350, 26.1050), width: 80, height: 80, child: _buildMapMarker("Ion", "Mediu", false)),
                  ],
                ),
              ],
            ),
          ),

          // --- BUTONUL "GĂSEȘTE-MĂ" ---
          Positioned(
            bottom: 220, 
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                _mapController.move(_myLocation, 14.5);
              },
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF1E88E5)),
            ),
          ),

          // --- PANOUL SOS (Fixat Jos) ---
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
                        const SnackBar(content: Text("🚨 Alerteză trimisă către voluntarii din zonă!"), backgroundColor: Colors.redAccent),
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

  // --- Meniul Lateral ---
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
                  onTap: () {},
                ),
                _buildMenuItem(Icons.calendar_month_rounded, "Programări", "Rezervă un interpret pt. mâine"),
                _buildMenuItem(Icons.menu_book_rounded, "Dicționar LSR", "Învață semne noi zilnic"),
                const Divider(height: 30),
                _buildMenuItem(Icons.emoji_events_rounded, "Clasament Eroi", "Top voluntari pe oraș", color: Colors.amber.shade700),
                _buildMenuItem(Icons.settings_rounded, "Setări", "Cont, notificări, intimitate", color: Colors.grey.shade700),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Revine la Login
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

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {Color color = const Color(0xFF1E88E5)}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildMapMarker(String name, String level, bool isOnline) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: isOnline ? Colors.green : Colors.transparent, width: 3),
          ),
          child: CircleAvatar(
            radius: 18, 
            backgroundColor: Colors.blue.shade50,
            child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E88E5))),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
          child: Text("$name • $level", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        )
      ],
    );
  }
}