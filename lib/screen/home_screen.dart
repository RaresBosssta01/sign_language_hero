import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:geolocator/geolocator.dart'; 

import 'login_screen.dart'; 
import 'profile_screen.dart'; 
import 'community_screen.dart'; 
import 'appointments_screen.dart';
import 'booking_screen.dart';
import 'dictionary_screen.dart'; // Importul necesar pentru Dicționar

// --------------------------------------------------------
// ECRANUL PRINCIPAL (HARTĂ LIVE ZENLY/SNAPCHAT STYLE)
// --------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String numeUtilizator;
  final String rol; 

  const HomeScreen({
    super.key, 
    this.numeUtilizator = "Utilizator", 
    this.rol = "voluntar",         
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final _supabase = Supabase.instance.client;
  
  // Date utilizator sincronizate live direct din Supabase
  late String _numeAfisat;
  late String _prenumeAfisat; 
  String _pozaProfilMea = '';
  String _timestampPoza = ''; 
  int _xp = 0;
  bool _esteVizibilPeHarta = true; 
  bool _isOnline = true; // Starea de Disponibilitate (Online/Offline)

  // Locația reală și Stream-urile
  LatLng _myLocation = const LatLng(44.4268, 26.1025);
  bool _locatieGasita = false;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<Map<String, dynamic>>>? _myProfileStream;

  @override
  void initState() {
    super.initState();
    _numeAfisat = widget.numeUtilizator;
    _prenumeAfisat = widget.numeUtilizator.split(' ').isNotEmpty ? widget.numeUtilizator.split(' ')[0] : "Utilizator"; 
    _timestampPoza = DateTime.now().millisecondsSinceEpoch.toString();
    
    _ascultaProfilulMeuLive(); 
    _startLiveLocation(); 
    _verificaModMentenanta();
  }

  @override
  void dispose() {
    _positionStream?.cancel(); 
    _myProfileStream?.cancel(); 
    super.dispose();
  }

  // --- 0. SINCRONIZARE LIVE A PROPRIULUI PROFIL ---
  void _ascultaProfilulMeuLive() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _myProfileStream = _supabase
        .from('profiluri')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) {
      if (data.isNotEmpty) {
        final profil = data.first;
        if (mounted) {
          setState(() {
            _xp = profil['xp'] ?? 0;
            _esteVizibilPeHarta = profil['vizibil_harta'] ?? true;
            _isOnline = profil['is_online'] ?? true;
            
            // Verificăm dacă s-a schimbat poza pentru a face update la Cache Buster
            String pozaNoua = profil['poza_profil'] ?? '';
            if (_pozaProfilMea != pozaNoua) {
              _timestampPoza = DateTime.now().millisecondsSinceEpoch.toString();
            }
            _pozaProfilMea = pozaNoua;
            
            String prenume = profil['prenume'] ?? '';
            String nume = profil['nume'] ?? '';
            if (prenume.isNotEmpty || nume.isNotEmpty) {
              _numeAfisat = "$prenume $nume".trim();
              _prenumeAfisat = prenume.isNotEmpty ? prenume : "Utilizator";
            }
          });
        }
      }
    });
  }

  // --- ALGORITM CALCUL NIVEL & EXPERIENȚĂ ---
  Map<String, dynamic> _calculeazaNivel(int xp) {
    if (xp < 100) return {'nivel': 1, 'titlu': 'Voluntar Începător 🌱', 'procent': xp / 100};
    if (xp < 300) return {'nivel': 2, 'titlu': 'Ajutor de Nădejde 🤝', 'procent': (xp - 100) / 200};
    if (xp < 600) return {'nivel': 3, 'titlu': 'Erou Local 🦸‍♂️', 'procent': (xp - 300) / 300};
    if (xp < 1000) return {'nivel': 4, 'titlu': 'Salvator Experimentat 🚑', 'procent': (xp - 600) / 400};
    if (xp < 2000) return {'nivel': 5, 'titlu': 'Maestru al Semnelor 🤟', 'procent': (xp - 1000) / 1000};
    return {'nivel': 6, 'titlu': 'Legendă a Comunității 👑', 'procent': 1.0}; 
  }

  // --- 1. LOCALIZARE GPS LIVE ---
  void _startLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) async {
      if (mounted) {
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
          _locatieGasita = true;
        });

        // Transmitem locația doar dacă voluntarul e și online, și vizibil
        if (widget.rol == 'voluntar' && _esteVizibilPeHarta && _isOnline) {
          try {
            await _supabase.from('profiluri').update({
              'lat': position.latitude,
              'lng': position.longitude,
            }).eq('id', _supabase.auth.currentUser!.id);
          } catch (e) {
            // Ignorăm erorile în fundal
          }
        }
      }
    });
  }

  // --- 2. SISTEM DE SECURITATE MENTENANȚĂ ---
  void _verificaModMentenanta() {
    if (widget.rol != 'admin') {
      _supabase.from('setari_sistem').stream(primaryKey: ['id']).eq('id', 1).listen((data) {
        if (data.isNotEmpty && data.first['mod_mentenanta'] == true) {
          if (!mounted) return;
          _supabase.auth.signOut();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aplicația a intrat în mentenanță!"), backgroundColor: Colors.redAccent));
        }
      });
    }
  }

  // --- 3. ACȚIUNE VOLUNTAR: ACCEPTĂ CEREREA ---
  Future<void> _acceptaUrgenta(String cerereId) async {
    try {
      await _supabase.from('programari').update({
        'voluntar_id': _supabase.auth.currentUser!.id,
        'status': 'confirmat'
      }).eq('id', cerereId);

      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Misiune Acceptată! Ai fost asigurat cazului."), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare: $e"), backgroundColor: Colors.redAccent));
    }
  }

  // --- 4. POP-UP CERERE DE URGENȚĂ ---
  void _arataDetaliiUrgenta(Map<String, dynamic> urgenta) {
    final lat = double.parse(urgenta['lat'].toString());
    final lng = double.parse(urgenta['lng'].toString());
    final distantaKm = const Distance().as(LengthUnit.Kilometer, _myLocation, LatLng(lat, lng)).toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.red.shade100,
                  child: const Icon(Icons.warning_amber_rounded, size: 35, color: Colors.red),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(urgenta['titlu'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text("La $distantaKm km distanță de tine", style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(urgenta['locatie_adresa'] ?? "Adresă nespecificată", style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 10),
            if (urgenta['nota_importanta'] != null && urgenta['nota_importanta'].toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text("Notă: ${urgenta['nota_importanta']}", style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("ACCEPTĂ CEREREA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _acceptaUrgenta(urgenta['id']),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- 5. POP-UP PROFIL VOLUNTAR PE HARTĂ ---
  void _arataProfilVoluntar(Map<String, dynamic> voluntar) {
    String nume = "${voluntar['prenume']} ${voluntar['nume']}";
    int xpVoluntar = voluntar['xp'] ?? 0;
    String pozaUrl = voluntar['poza_profil'] ?? '';
    Map<String, dynamic> nivelVoluntar = _calculeazaNivel(xpVoluntar);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 260,
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal.shade100,
              backgroundImage: pozaUrl.isNotEmpty ? NetworkImage(pozaUrl) : null,
              child: pozaUrl.isEmpty ? Text(nume.isNotEmpty ? nume[0].toUpperCase() : '?', style: const TextStyle(fontSize: 30, color: Colors.teal, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(height: 15),
            Text(nume, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 5),
                Text("${nivelVoluntar['titlu']} (Nivel ${nivelVoluntar['nivel']})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            const Text("Acesta este un voluntar activ în zona ta. Cere ajutor pentru a-l notifica!", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center,)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isVoluntar = widget.rol == 'voluntar';
    Map<String, dynamic> nivelData = _calculeazaNivel(_xp);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true, 
      
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isVoluntar ? Colors.tealAccent.shade400 : const Color(0xFF1E88E5),
              backgroundImage: _pozaProfilMea.isNotEmpty ? NetworkImage("$_pozaProfilMea?v=$_timestampPoza") : null,
              child: _pozaProfilMea.isEmpty ? Text(isVoluntar ? "🦸‍♂️" : "👋", style: const TextStyle(fontSize: 18)) : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Salut, $_prenumeAfisat!", style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                if (isVoluntar)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14), 
                      const SizedBox(width: 4), 
                      Text("$_xp XP (${nivelData['titlu']})", style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold))
                    ]
                  )
                else 
                   Text("Membru Comunitate", style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 32), onPressed: () => _scaffoldKey.currentState!.openEndDrawer()),
          const SizedBox(width: 10),
        ],
      ),

      endDrawer: _buildDrawerMenu(isVoluntar, nivelData),

      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _myLocation, 
                initialZoom: 14.5, 
                minZoom: 5.0, 
                maxZoom: 19.0, 
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all)
              ),
              children: [
                TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c', 'd'], userAgentPackageName: 'com.signlanguagehero.app'),
                
                // STRATUL 1: LOCAȚIA MEA CURENTĂ 
                MarkerLayer(markers: [
                  Marker(
                    point: _myLocation, 
                    width: 250, 
                    height: 120, 
                    child: _buildSnapchatStyleMarker(_numeAfisat, _pozaProfilMea, isMe: true)
                  )
                ]),

                // STRATUL 2: URGENȚELE (VĂZUTE DE VOLUNTAR)
                if (isVoluntar)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase.from('programari').stream(primaryKey: ['id']).eq('status', 'în așteptare'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const MarkerLayer(markers: []);
                      
                      final urgente = snapshot.data!.where((p) => p['voluntar_id'] == null && p['lat'] != null && p['lng'] != null).toList();
                      List<Marker> piniUrgente = urgente.map((urgenta) {
                        return Marker(
                          point: LatLng(double.parse(urgenta['lat'].toString()), double.parse(urgenta['lng'].toString())),
                          width: 80, height: 80,
                          child: GestureDetector(
                            onTap: () => _arataDetaliiUrgenta(urgenta),
                            child: _buildRedEmergencyMarker()
                          )
                        );
                      }).toList();

                      return MarkerLayer(markers: piniUrgente);
                    },
                  ),

                // STRATUL 3: VOLUNTARII ACTIVI (VĂZUȚI DE BENEFICIAR)
                if (!isVoluntar)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase.from('profiluri').stream(primaryKey: ['id']).eq('rol', 'voluntar'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const MarkerLayer(markers: []);

                      final voluntariActivi = snapshot.data!.where((v) => 
                        v['lat'] != null && 
                        v['lng'] != null && 
                        v['is_online'] == true && 
                        v['vizibil_harta'] == true
                      ).toList();
                      
                      List<Marker> piniVoluntari = voluntariActivi.map((v) {
                        return Marker(
                          point: LatLng(double.parse(v['lat'].toString()), double.parse(v['lng'].toString())),
                          width: 250, 
                          height: 120, 
                          child: GestureDetector(
                            onTap: () => _arataProfilVoluntar(v),
                            child: _buildSnapchatStyleMarker(
                              v['prenume'] != null ? "${v['prenume']} ${v['nume'] ?? ''}".trim() : "Voluntar", 
                              v['poza_profil']
                            )
                          )
                        );
                      }).toList();

                      return MarkerLayer(markers: piniVoluntari);
                    }
                  )
              ],
            ),
          ),

          // Buton de centrare hartă
          Positioned(
            bottom: 110, right: 20,
            child: FloatingActionButton(backgroundColor: Colors.white, elevation: 4, onPressed: () => _mapController.move(_myLocation, 14.5), child: const Icon(Icons.my_location_rounded, color: Color(0xFF1E88E5))),
          ),

          // SLEEK ACTION BAR (Înlocuiește butoanele vechi)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: _locatieGasita ? Colors.green : Colors.orange, size: 12),
                  const SizedBox(width: 15),
                  Expanded(
                    child: isVoluntar 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(_isOnline ? "DISPONIBIL" : "OFFLINE", style: TextStyle(color: _isOnline ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                          Switch(
                            value: _isOnline,
                            activeColor: Colors.green,
                            onChanged: (val) async {
                              setState(() => _isOnline = val);
                              await _supabase.from('profiluri').update({'is_online': val}).eq('id', _supabase.auth.currentUser!.id);
                            },
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen())),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
                        child: const Text("CERE AJUTOR ACUM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // --- UI: Pinul Roșu de Urgență ---
  Widget _buildRedEmergencyMarker() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 5)]),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
        ),
        Container(
          margin: const EdgeInsets.only(top: 5),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
          child: const Text("URGENȚĂ", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
        )
      ],
    );
  }

  // --- UI: Pin Stil Snapchat / Zenly ---
  Widget _buildSnapchatStyleMarker(String nume, String? pozaUrl, {bool isMe = false}) {
    String finalUrl = pozaUrl ?? '';
    if (isMe && finalUrl.isNotEmpty) {
      finalUrl = "$finalUrl?v=$_timestampPoza";
    }

    String displayName = nume;
    if (displayName.length > 15) {
      displayName = "${displayName.substring(0, 13)}...";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 55, 
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3), 
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
            image: finalUrl.isNotEmpty
                ? DecorationImage(image: NetworkImage(finalUrl), fit: BoxFit.cover)
                : null,
            color: Colors.grey.shade300, 
          ),
          child: finalUrl.isEmpty
              ? Center(
                  child: Text(
                    nume.isNotEmpty ? nume[0].toUpperCase() : '?', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 24)
                  )
                )
              : null,
        ),
        const SizedBox(height: 6), 
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.85), 
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
          ),
          child: Text(
            displayName,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }

  // =========================================================================
  // MENIUL LATERAL (DRAWER)
  // =========================================================================
  Widget _buildDrawerMenu(bool isVoluntar, Map<String, dynamic> nivelData) {
    Color themeColor = isVoluntar ? const Color(0xFF00796B) : const Color(0xFF1E88E5);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isVoluntar ? [const Color(0xFF00796B), const Color(0xFF009688)] : [const Color(0xFF1E88E5), const Color(0xFF1565C0)], 
                begin: Alignment.topLeft, end: Alignment.bottomRight
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40, 
                  backgroundColor: Colors.white, 
                  backgroundImage: _pozaProfilMea.isNotEmpty ? NetworkImage("$_pozaProfilMea?v=$_timestampPoza") : null,
                  child: _pozaProfilMea.isEmpty ? Text(_prenumeAfisat.isNotEmpty ? _prenumeAfisat[0].toUpperCase() : '?', style: TextStyle(fontSize: 40, color: themeColor)) : null,
                ),
                const SizedBox(height: 15),
                Text(_numeAfisat, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                if (isVoluntar)
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10), 
                          child: LinearProgressIndicator(
                            value: nivelData['procent'], 
                            backgroundColor: Colors.white24, 
                            color: Colors.amber.shade400, 
                            minHeight: 8
                          )
                        )
                      ), 
                      const SizedBox(width: 10), 
                      Text("Nivel ${nivelData['nivel']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    ]
                  )
                else
                   const Text("Cont Verificat", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(Icons.map_rounded, isVoluntar ? "Radar Intervenții" : "Harta Urgențelor", "Statusul live al zonei", themeColor, () => Navigator.pop(context)),
                
                _buildMenuItem(Icons.calendar_month_rounded, "Programări", "Calendar și solicitări", themeColor, () {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentsScreen(rol: widget.rol)));
                }),

                ListTile(
                  leading: Icon(Icons.forum_rounded, color: themeColor, size: 28),
                  title: const Text("Comunitate & Feed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text("Mesaje, suport și discuții"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                    child: const Text("Live", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()));
                  },
                ),

                if (!isVoluntar)
                  _buildMenuItem(Icons.add_circle_outline, "Solicită Interpret", "Fă o cerere nouă", Colors.green, () { Navigator.pop(context);Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen()));}),
                
                if (isVoluntar)
                  ListTile(
                    leading: Icon(Icons.menu_book_rounded, color: themeColor, size: 28),
                    title: const Text("Dicționar LSR (AI)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text("Învață semne noi zilnic"),
                    trailing: const Icon(Icons.auto_awesome, color: Colors.amber), 
                    onTap: () {
                      Navigator.pop(context); 
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DictionaryScreen()));
                    },
                  ),
                  
                const Divider(height: 30),

                ListTile(
                  leading: Icon(Icons.settings_rounded, color: Colors.grey.shade700, size: 28),
                  title: const Text("Profil & Setări", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: const Text("Cont, locație, intimitate"),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: OutlinedButton.icon(
              onPressed: () async {
                if (isVoluntar) {
                   await _supabase.from('profiluri').update({'is_online': false}).eq('id', _supabase.auth.currentUser!.id);
                }
                await Supabase.instance.client.auth.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text("Deconectare", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), minimumSize: const Size(double.infinity, 50)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}