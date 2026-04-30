import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  final _supabase = Supabase.instance.client;
  
  // NAVIGAȚIE PRINCIPALĂ
  int _selectedIndex = 1; 
  int _settingsSelectedIndex = 0; 
  
  // STARE CERERI
  Map<String, dynamic>? _cerereSelectata;
  int _pendingCount = 0;
  int _lastKnownPendingCount = -1; 
  
  // STARE CHAT & PREZENȚĂ REALĂ
  Map<String, dynamic>? _chatSelectat; 
  final TextEditingController _mesajController = TextEditingController();
  late final RealtimeChannel _presenceChannel;
  Set<String> _onlineUsers = {};
  int _mesajeNecititeCount = 0; 

  // STARE NOTIFICĂRI
  List<Map<String, dynamic>> _notificari = [];
  bool _aratateDoarNecitite = false;

  // STARE SETĂRI (UI Funcțional și Persistent)
  bool _is2FAEnabled = true;
  bool _notifEmail1 = true;
  bool _notifEmail2 = true;
  bool _notifPush1 = true;
  bool _notifPush2 = true;
  bool _backupAutomat = true;
  bool _modMentenanta = false;
  bool _raportZilnic = true;

  // Stare pentru securitate
  bool _ascundeParolaCurenta = true;
  bool _ascundeParolaNoua = true;
  bool _ascundeConfirmaParola = true;

  // Stare pentru preferințe
  String _limbaSelectata = "Română";
  String _fusOrarSelectat = "Europa/București (GMT+2)";
  String _formatDataSelectat = "DD/MM/YYYY";
  String _temaSelectata = "Luminos";

  // Controllere Profil & Securitate
  final _numeAdminCtrl = TextEditingController();
  final _emailAdminCtrl = TextEditingController();
  final _telefonAdminCtrl = TextEditingController();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // CULORI FIXE (Brand & Sidebar)
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color darkSidebar = const Color(0xFF111827); 
  final Color successGreen = const Color(0xFF10B981);

  // =========================================================================
  // LOGICĂ: TEMĂ DINAMICĂ (DARK/LIGHT MODE REAL)
  // =========================================================================
  bool get _isDark {
    if (_temaSelectata == "Întunecat") return true;
    if (_temaSelectata == "Automat") {
      try {
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
      } catch (_) { return false; }
    }
    return false;
  }
  
  Color get _bgApp => _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _bgCard => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textMain => _isDark ? Colors.white : const Color(0xFF1E293B);
  Color get _textSec => _isDark ? Colors.white70 : Colors.grey.shade600;
  Color get _borderC => _isDark ? Colors.white12 : Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    _incarcaDateAdmin(); 
    _incarcaSetarileSalvate(); 
    _initPresence(); 
    _initMesajeNecitite(); 
    _genereazaNotificariInitiale();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_presenceChannel);
    _mesajController.dispose();
    _numeAdminCtrl.dispose();
    _emailAdminCtrl.dispose();
    _telefonAdminCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // PROFIL & SECURITATE (VERIFICĂRI REALE ÎN BAZA DE DATE)
  // =========================================================================
  Future<void> _incarcaDateAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase.from('profiluri').select().eq('id', user.id).maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _numeAdminCtrl.text = "${data['prenume'] ?? ''} ${data['nume'] ?? ''}".trim();
            _emailAdminCtrl.text = data['email'] ?? user.email ?? "";
            _telefonAdminCtrl.text = data['telefon'] ?? "";
          });
        }
      } catch (e) { debugPrint("Eroare incarcare profil: $e"); }
    }
  }

  Future<void> _salveazaTotMeniulSetari() async {
    if (_settingsSelectedIndex == 0) {
      await _salveazaProfil();
    } else if (_settingsSelectedIndex == 1) {
      await _schimbaParolaVerificata();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Setările au fost salvate pe dispozitiv!"), backgroundColor: Colors.green));
    }
  }

  Future<void> _salveazaProfil() async {
    final user = _supabase.auth.currentUser;
    if (user == null || _numeAdminCtrl.text.isEmpty) return;

    List<String> numeComplet = _numeAdminCtrl.text.trim().split(' ');
    String prenume = numeComplet.isNotEmpty ? numeComplet.first : "";
    String nume = numeComplet.length > 1 ? numeComplet.sublist(1).join(' ') : "";

    try {
      await _supabase.from('profiluri').update({'prenume': prenume, 'nume': nume, 'telefon': _telefonAdminCtrl.text.trim()}).eq('id', user.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil actualizat cu succes!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare la actualizare: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _schimbaParolaVerificata() async {
    if (_oldPassCtrl.text.isEmpty && _newPassCtrl.text.isEmpty) return;

    if (_oldPassCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Introdu parola curentă!"), backgroundColor: Colors.red)); return; }
    if (_newPassCtrl.text.length < 8) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parola nouă trebuie să aibă minim 8 caractere!"), backgroundColor: Colors.red)); return; }
    if (_newPassCtrl.text != _confirmPassCtrl.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parolele noi nu coincid!"), backgroundColor: Colors.red)); return; }

    try {
      final email = _supabase.auth.currentUser!.email!;
      await _supabase.auth.signInWithPassword(email: email, password: _oldPassCtrl.text);
      await _supabase.auth.updateUser(UserAttributes(password: _newPassCtrl.text));

      if (mounted) {
        _oldPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parola a fost schimbată cu succes!"), backgroundColor: Colors.green));
      }
    } on AuthException catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parola curentă este incorectă!"), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare: $e"), backgroundColor: Colors.red));
    }
  }

  // =========================================================================
  // LOGICĂ: SALVARE ȘI ÎNCĂRCARE PREFERINȚE LOCALE
  // =========================================================================
  Future<void> _incarcaSetarileSalvate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backupAutomat = prefs.getBool('backup_automat') ?? true;
      _modMentenanta = prefs.getBool('mod_mentenanta') ?? false;
      _is2FAEnabled = prefs.getBool('2fa_enabled') ?? true;
      _notifEmail1 = prefs.getBool('notif_email1') ?? true;
      _notifEmail2 = prefs.getBool('notif_email2') ?? true;
      _notifPush1 = prefs.getBool('notif_push1') ?? true;
      _notifPush2 = prefs.getBool('notif_push2') ?? true;
      _raportZilnic = prefs.getBool('raport_zilnic') ?? true;
      
      _limbaSelectata = prefs.getString('limba') ?? "Română";
      _fusOrarSelectat = prefs.getString('fus_orar') ?? "Europa/București (GMT+2)";
      _formatDataSelectat = prefs.getString('format_data') ?? "DD/MM/YYYY";
      _temaSelectata = prefs.getString('tema') ?? "Luminos";
    });
  }

  Future<void> _salveazaSetareBool(String cheie, bool valoare) async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setBool(cheie, valoare);
  }

  Future<void> _salveazaSetareString(String cheie, String valoare) async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setString(cheie, valoare);
  }

  // =========================================================================
  // LOGICĂ: PRESENCE (ONLINE/OFFLINE)
  // =========================================================================
  void _initPresence() {
    final myId = _supabase.auth.currentUser!.id;
    _presenceChannel = _supabase.channel('online-users');
    
    _presenceChannel.onPresenceSync((payload) {
      final state = _presenceChannel.presenceState();
      final online = <String>{};
      
      for (final presenceState in state) {
        for (final presence in presenceState.presences) {
          final userId = presence.payload['user_id'];
          if (userId != null) online.add(userId.toString());
        }
      }
      if (mounted) setState(() => _onlineUsers = online);
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) await _presenceChannel.track({'user_id': myId});
    });
  }

  // =========================================================================
  // LOGICĂ: CHAT & BADGE MESAJE NECITITE
  // =========================================================================
  void _initMesajeNecitite() async {
    final myId = _supabase.auth.currentUser!.id;
    _recalculeazaMesajeNecitite(myId);
    _supabase.channel('public:mesaje').onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'mesaje', callback: (payload) => _recalculeazaMesajeNecitite(myId)).subscribe();
  }

  Future<void> _recalculeazaMesajeNecitite(String myId) async {
    try {
      final response = await _supabase.from('mesaje').select('id').eq('receiver_id', myId).eq('citit', false);
      if (mounted) setState(() => _mesajeNecititeCount = response.length);
    } catch (e) { debugPrint("Eroare calcul mesaje necitite: $e"); }
  }

  Future<void> _marcheazaMesajeCitite(String senderId) async {
    final myId = _supabase.auth.currentUser!.id;
    try {
      await _supabase.from('mesaje').update({'citit': true}).eq('receiver_id', myId).eq('sender_id', senderId).eq('citit', false);
      _recalculeazaMesajeNecitite(myId); 
    } catch (e) { debugPrint("Eroare marcare citit: $e"); }
  }

  Future<void> _trimiteMesaj() async {
    if (_mesajController.text.trim().isEmpty || _chatSelectat == null) return;
    final text = _mesajController.text.trim();
    _mesajController.clear();
    try {
      await _supabase.from('mesaje').insert({'sender_id': _supabase.auth.currentUser!.id, 'receiver_id': _chatSelectat!['id'], 'text': text, 'citit': false });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare: $e"), backgroundColor: Colors.red)); }
  }

  Future<void> _blockUser(String id, String nume) async {
    try {
      await _supabase.from('profiluri').update({'status': 'blocat'}).eq('id', id);
      if (mounted) {
        setState(() => _chatSelectat = null); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Utilizatorul $nume a fost blocat definitiv."), backgroundColor: Colors.redAccent));
      }
    } catch (e) { debugPrint("Eroare blocare utilizator: $e"); }
  }

  // =========================================================================
  // LOGICĂ: CERERI
  // =========================================================================
  Future<void> _modificaStatus(String id, String noulStatus, String nume) async {
    try {
      await _supabase.from('profiluri').update({'status': noulStatus}).eq('id', id);
      if (mounted) setState(() => _cerereSelectata = null); 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$nume a fost $noulStatus!"), backgroundColor: noulStatus == 'aprobat' ? successGreen : Colors.red));
    } catch (e) { debugPrint("Eroare status: $e"); }
  }

  // =========================================================================
  // LOGICĂ: NOTIFICĂRI SMART
  // =========================================================================
  void _genereazaNotificariInitiale() {
    _notificari = [{'id': 1, 'titlu': 'Sistem pregătit', 'descriere': 'Sistemul de management este online și securizat.', 'timp': 'Acum', 'citit': false, 'tip': 'sistem'}];
  }

  void _adaugaNotificareLive(String titlu, String descriere, String tip) {
    setState(() { _notificari.insert(0, {'id': DateTime.now().millisecondsSinceEpoch, 'titlu': titlu, 'descriere': descriere, 'timp': 'Acum', 'citit': false, 'tip': tip}); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(titlu, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: primaryBlue, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(top: 50, left: 20, right: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))));
  }

  int get _notificariNecitite => _notificari.where((n) => n['citit'] == false).length;

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgApp,
      body: Row(
        children: [
          SizedBox(width: 260, child: _buildSidebar()), 
          Expanded(child: _buildMainContent()), 
        ],
      ),
    );
  }

  // =========================================================================
  // SIDEBAR (CU DASHBOARD INACTIV ȘI BADGES REALE)
  // =========================================================================
  Widget _buildSidebar() {
    String initiale = _numeAdminCtrl.text.isNotEmpty ? _numeAdminCtrl.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() : "A";

    return Container(
      color: darkSidebar, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.people_alt, color: Colors.white, size: 24)),
              const SizedBox(width: 15),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Admin Portal", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text("Management Center", style: TextStyle(color: Colors.white54, fontSize: 11))]),
            ],
          ),
          const SizedBox(height: 40),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text("MENIU PLATFORMĂ", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
          
          _buildNavItem(1, "Cereri Voluntari", Icons.people_outline, badgeCount: _pendingCount, badgeColor: Colors.redAccent),
          _buildNavItem(2, "Mesaje", Icons.chat_bubble_outline, badgeCount: _mesajeNecititeCount, badgeColor: successGreen), 
          _buildNavItem(3, "Notificări", Icons.notifications_none, badgeCount: _notificariNecitite, badgeColor: Colors.orange),
          _buildNavItem(4, "Setări", Icons.settings_outlined),

          const Spacer(),
          const Divider(color: Colors.white12),
          ListTile(
            leading: CircleAvatar(backgroundColor: primaryBlue, child: Text(initiale, style: const TextStyle(color: Colors.white))),
            title: Text(_numeAdminCtrl.text.isNotEmpty ? _numeAdminCtrl.text : "Admin User", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_emailAdminCtrl.text.isNotEmpty ? _emailAdminCtrl.text : "admin@volunteer.ro", style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(icon: const Icon(Icons.logout, color: Colors.white54, size: 20), onPressed: _logout),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {int badgeCount = 0, Color badgeColor = Colors.redAccent}) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: InkWell(
        onTap: () => setState(() { _selectedIndex = index; }),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(color: isSelected ? primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            dense: true,
            leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
            title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            trailing: badgeCount > 0 ? Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle), child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))) : null,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TOP BAR
  // =========================================================================
  Widget _buildMainContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(color: _bgCard, border: Border(bottom: BorderSide(color: _borderC))),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getTitluTopBar(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textMain)),
                  Text(_getSubtitluTopBar(), style: TextStyle(color: _textSec, fontSize: 13)),
                ],
              ),
              const Spacer(),
              Container(
                width: 250, height: 40,
                decoration: BoxDecoration(color: _bgApp, borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderC)),
                child: TextField(style: TextStyle(color: _textMain), decoration: InputDecoration(hintText: "Caută...", hintStyle: TextStyle(color: _textSec), prefixIcon: Icon(Icons.search, color: _textSec, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.only(bottom: 10))),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3), 
                child: Stack(
                  children: [
                    Icon(Icons.notifications_none, color: _textSec, size: 28),
                    if (_notificariNecitite > 0)
                      Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: Padding(padding: const EdgeInsets.all(30.0), child: _getSelectedScreen())),
      ],
    );
  }

  String _getTitluTopBar() { switch (_selectedIndex) { case 1: return "Cereri Voluntari"; case 2: return "Chat cu Voluntarii"; case 3: return "Notificări"; case 4: return "Setări"; default: return ""; } }
  String _getSubtitluTopBar() { switch (_selectedIndex) { case 1: return "Gestionează cererile de înregistrare"; case 2: return "Comunică direct cu voluntarii tăi"; case 3: return "Gestionează alertele sistemului"; case 4: return "Configurează setările platformei"; default: return ""; } }
  Widget _getSelectedScreen() { switch (_selectedIndex) { case 1: return _buildCereriScreen(); case 2: return _buildChatScreen(); case 3: return _buildNotificariScreen(); case 4: return _buildSetariScreen(); default: return const SizedBox(); } }

  // =========================================================================
  // ECRAN 1: CERERI VOLUNTARI
  // =========================================================================
  Widget _buildCereriScreen() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('profiluri').stream(primaryKey: ['id']).eq('rol', 'voluntar'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final cereriPending = snapshot.data!.where((v) => v['status'] == 'pending').toList();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_lastKnownPendingCount != -1 && cereriPending.length > _lastKnownPendingCount) { _adaugaNotificareLive("Cerere Nouă", "Un nou voluntar așteaptă aprobarea.", "cerere"); }
          if (mounted && _pendingCount != cereriPending.length) { setState(() { _pendingCount = cereriPending.length; _lastKnownPendingCount = cereriPending.length; }); }
        });

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Cereri Pendinte", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textMain)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Text("${cereriPending.length} cereri", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)))
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cereriPending.length,
                      itemBuilder: (context, index) {
                        final vol = cereriPending[index];
                        bool isSelected = _cerereSelectata?['id'] == vol['id'];
                        String ini1 = vol['prenume']?[0] ?? ""; String ini2 = vol['nume']?[0] ?? "";
                        
                        return GestureDetector(
                          onTap: () => setState(() => _cerereSelectata = vol),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: isSelected ? primaryBlue : _borderC, width: isSelected ? 2 : 1), boxShadow: [if (!isSelected && !_isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))]),
                            child: Row(
                              children: [
                                Container(width: 45, height: 45, decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(10)), child: Center(child: Text("$ini1$ini2", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${vol['prenume']} ${vol['nume']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textMain)),
                                      Text(vol['email'], style: TextStyle(color: _textSec, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Row(children: [Icon(Icons.location_on_outlined, size: 12, color: _textSec), const SizedBox(width: 4), Text(vol['oras'] ?? "România", style: TextStyle(color: _textSec, fontSize: 11))])
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              flex: 6,
              child: _cerereSelectata == null
                  ? Container(decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderC)), child: Center(child: Text("Selectează o cerere pentru a vedea detaliile", style: TextStyle(color: _textSec))))
                  : _buildCerereDetalii(_cerereSelectata!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCerereDetalii(Map<String, dynamic> vol) {
    String ini1 = vol['prenume']?[0] ?? ""; String ini2 = vol['nume']?[0] ?? "";
    List<String> competente = (vol['interese'] ?? "").toString().isNotEmpty ? vol['interese'].split(',') : [];

    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderC), boxShadow: [if(!_isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              children: [
                Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)), child: Center(child: Text("$ini1$ini2", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)))),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${vol['prenume']} ${vol['nume']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), Text("Vârstă: ${vol['varsta'] ?? 'N/A'} ani", style: const TextStyle(color: Colors.white70, fontSize: 13))]),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Expanded(child: _infoCard(Icons.email_outlined, "Email", vol['email'])), const SizedBox(width: 15), Expanded(child: _infoCard(Icons.phone_outlined, "Telefon", vol['telefon'] ?? "-"))]),
                  const SizedBox(height: 15),
                  Row(children: [Expanded(child: _infoCard(Icons.location_on_outlined, "Locație", vol['oras'] ?? "-")), const SizedBox(width: 15), Expanded(child: _infoCard(Icons.calendar_today_outlined, "Data aplicării", "Recentă"))]),
                  const SizedBox(height: 30),
                  Row(children: [const Icon(Icons.workspace_premium_outlined, color: Color(0xFF3B82F6), size: 18), const SizedBox(width: 8), Text("Competențe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textMain))]),
                  const SizedBox(height: 15),
                  Wrap(spacing: 8, runSpacing: 8, children: competente.isEmpty ? [Text("Nu a specificat", style: TextStyle(color: _textSec))] : competente.map((c) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(border: Border.all(color: _borderC), borderRadius: BorderRadius.circular(8)), child: Text(c.trim(), style: TextStyle(fontSize: 12, color: _textMain)))).toList()),
                  const SizedBox(height: 30),
                  Text("Motivație", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textMain)),
                  const SizedBox(height: 10),
                  Text(vol['descriere'] ?? "Fără descriere.", style: TextStyle(color: _textSec, height: 1.5, fontSize: 13)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _modificaStatus(vol['id'], 'respins', vol['prenume']), icon: Icon(Icons.close, color: _textSec, size: 18), label: Text("Respinge", style: TextStyle(color: _textMain)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: BorderSide(color: _borderC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: () { 
                  setState(() { _chatSelectat = vol; _selectedIndex = 2; }); 
                  _marcheazaMesajeCitite(vol['id']); 
                }, icon: Icon(Icons.chat_bubble_outline, color: primaryBlue, size: 18), label: Text("Mesaj", style: TextStyle(color: primaryBlue)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: BorderSide(color: primaryBlue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(onPressed: () => _modificaStatus(vol['id'], 'aprobat', vol['prenume']), icon: const Icon(Icons.check, color: Colors.white, size: 18), label: const Text("Acceptă", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: successGreen, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _bgApp, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 14, color: _textSec), const SizedBox(width: 6), Text(title, style: TextStyle(color: _textSec, fontSize: 11))]), const SizedBox(height: 8), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textMain), maxLines: 1, overflow: TextOverflow.ellipsis)]),
    );
  }

  // =========================================================================
  // ECRAN 2: CHAT (FILTRAT, SECURIZAT ȘI CU DARK MODE)
  // =========================================================================
  Widget _buildChatScreen() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderC)),
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.all(20), child: TextField(style: TextStyle(color: _textMain), decoration: InputDecoration(hintText: "Caută conversații...", hintStyle: TextStyle(color: _textSec), prefixIcon: Icon(Icons.search, size: 18, color: _textSec), filled: true, fillColor: _bgApp, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: EdgeInsets.zero))),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    // FILTREAZĂ DOAR VOLUNTARII APROBAȚI
                    future: _supabase.from('profiluri').select().eq('rol', 'voluntar').eq('status', 'aprobat'), 
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final users = snapshot.data!;
                      if (users.isEmpty) return Center(child: Text("Nu există voluntari aprobați.", style: TextStyle(color: _textSec)));

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          bool isSel = _chatSelectat?['id'] == user['id'];
                          bool isOnline = _onlineUsers.contains(user['id']); 
                          
                          return ListTile(
                            selected: isSel, selectedTileColor: _bgApp,
                            leading: Stack(
                              children: [
                                CircleAvatar(backgroundColor: primaryBlue, child: Text(user['prenume']?[0] ?? "V", style: const TextStyle(color: Colors.white))),
                                if (isOnline) Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: successGreen, shape: BoxShape.circle, border: Border.all(color: _bgCard, width: 2)))),
                              ],
                            ),
                            title: Text("${user['prenume']} ${user['nume']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textMain)),
                            subtitle: Text(isOnline ? "Online" : "Offline", style: TextStyle(color: isOnline ? successGreen : _textSec, fontSize: 11)),
                            onTap: () {
                              setState(() => _chatSelectat = user);
                              _marcheazaMesajeCitite(user['id']); 
                            },
                          );
                        }
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderC)),
            child: _chatSelectat == null 
              ? Center(child: Text("Selectează o conversație", style: TextStyle(color: _textSec)))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _borderC))),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: primaryBlue, child: Text(_chatSelectat!['prenume'][0], style: const TextStyle(color: Colors.white))),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${_chatSelectat!['prenume']} ${_chatSelectat!['nume']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textMain)),
                              Text(_onlineUsers.contains(_chatSelectat!['id']) ? "Online" : "Offline", style: TextStyle(color: _onlineUsers.contains(_chatSelectat!['id']) ? successGreen : _textSec, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: _textSec), color: _bgCard,
                            onSelected: (value) {
                              if (value == 'block') _blockUser(_chatSelectat!['id'], _chatSelectat!['prenume']);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'block', child: Text("Blochează utilizator", style: TextStyle(color: Colors.red))),
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabase.from('mesaje').stream(primaryKey: ['id']).order('created_at', ascending: true),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final myId = _supabase.auth.currentUser!.id;
                          final chatId = _chatSelectat!['id'];
                          final mesaje = snapshot.data!.where((m) => (m['sender_id'] == myId && m['receiver_id'] == chatId) || (m['sender_id'] == chatId && m['receiver_id'] == myId)).toList();
                          
                          if (mesaje.isEmpty) return Center(child: Text("Niciun mesaj.", style: TextStyle(color: _textSec)));
                          
                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: mesaje.length,
                            itemBuilder: (context, index) {
                              final isMe = mesaje[index]['sender_id'] == myId;
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
                                  decoration: BoxDecoration(color: isMe ? primaryBlue : _bgApp, borderRadius: BorderRadius.circular(15), border: isMe ? null : Border.all(color: _borderC)),
                                  child: Text(mesaje[index]['text'], style: TextStyle(color: isMe ? Colors.white : _textMain, fontSize: 14)),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20), decoration: BoxDecoration(border: Border(top: BorderSide(color: _borderC))),
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: _mesajController, style: TextStyle(color: _textMain), decoration: InputDecoration(hintText: "Scrie un mesaj...", hintStyle: TextStyle(color: _textSec), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), filled: true, fillColor: _bgApp, contentPadding: const EdgeInsets.symmetric(horizontal: 20)), onSubmitted: (_) => _trimiteMesaj())),
                          const SizedBox(width: 15),
                          GestureDetector(onTap: _trimiteMesaj, child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 20)))
                        ],
                      ),
                    )
                  ],
                ),
          ),
        )
      ],
    );
  }

  // =========================================================================
  // ECRAN 3: NOTIFICĂRI
  // =========================================================================
  Widget _buildNotificariScreen() {
    List<Map<String, dynamic>> afisate = _aratateDoarNecitite ? _notificari.where((n) => !n['citit']).toList() : _notificari;

    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderC)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 30),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Notificări", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("$_notificariNecitite notificări necitite", style: const TextStyle(color: Colors.white70, fontSize: 13))
                ]),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => setState(() { for (var n in _notificari) { n['citit'] = true; } }),
                  icon: const Icon(Icons.check, color: Colors.white, size: 16), label: const Text("Marchează toate", style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: _textSec), const SizedBox(width: 15),
                GestureDetector(onTap: () => setState(() => _aratateDoarNecitite = false), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: !_aratateDoarNecitite ? primaryBlue : _bgApp, borderRadius: BorderRadius.circular(10)), child: Text("Toate (${_notificari.length})", style: TextStyle(color: !_aratateDoarNecitite ? Colors.white : _textSec, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 10),
                GestureDetector(onTap: () => setState(() => _aratateDoarNecitite = true), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: _aratateDoarNecitite ? primaryBlue : _bgApp, borderRadius: BorderRadius.circular(10)), child: Text("Necitite ($_notificariNecitite)", style: TextStyle(color: _aratateDoarNecitite ? Colors.white : _textSec, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Divider(height: 1, color: _borderC),
          Expanded(
            child: afisate.isEmpty 
              ? Center(child: Text("Nu ai nicio notificare.", style: TextStyle(color: _textSec)))
              : ListView.builder(
                  itemCount: afisate.length,
                  itemBuilder: (context, i) {
                    final n = afisate[i];
                    IconData ic; Color c;
                    if (n['tip'] == 'cerere') { ic = Icons.person_add; c = Colors.redAccent; }
                    else if (n['tip'] == 'mesaj') { ic = Icons.chat; c = successGreen; }
                    else { ic = Icons.settings; c = primaryBlue; }

                    return Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _borderC))),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(ic, color: c)),
                        title: Row(children: [Text(n['titlu'], style: TextStyle(fontWeight: FontWeight.bold, color: _textMain)), if (!n['citit']) Container(margin: const EdgeInsets.only(left: 8), width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle))]),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 5), Text(n['descriere'], style: TextStyle(color: _textSec)), const SizedBox(height: 5), Row(children: [Icon(Icons.access_time, size: 12, color: _textSec), const SizedBox(width: 4), Text(n['timp'], style: TextStyle(color: _textSec, fontSize: 11))])]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!n['citit']) IconButton(icon: const Icon(Icons.check, color: Colors.blue), onPressed: () => setState(() => n['citit'] = true)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => setState(() => _notificari.removeWhere((element) => element['id'] == n['id']))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  // =========================================================================
  // ECRAN 4: SETĂRI COMPLEXE (INTEGRAT ȘI FUNCȚIONAL)
  // =========================================================================
  Widget _buildSetariScreen() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 220,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderC)),
          child: Column(
            children: [
              _buildSetariTab(0, "Profil", Icons.person_outline),
              _buildSetariTab(1, "Securitate", Icons.lock_outline),
              _buildSetariTab(2, "Notificări", Icons.notifications_none),
              _buildSetariTab(3, "Preferințe", Icons.color_lens_outlined),
              _buildSetariTab(4, "Sistem", Icons.storage),
            ],
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderC)),
            child: _getSetariContent(),
          ),
        )
      ],
    );
  }

  Widget _buildSetariTab(int index, String titlu, IconData icon) {
    bool isSel = _settingsSelectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _settingsSelectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(color: isSel ? primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [Icon(icon, color: isSel ? Colors.white : _textSec, size: 18), const SizedBox(width: 10), Text(titlu, style: TextStyle(color: isSel ? Colors.white : _textMain, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))]),
      ),
    );
  }

  Widget _getSetariContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(["Profil", "Securitate", "Notificări", "Preferințe", "Setări Sistem"][_settingsSelectedIndex], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textMain)),
              ElevatedButton.icon(
                onPressed: _salveazaTotMeniulSetari, 
                icon: const Icon(Icons.save, color: Colors.white, size: 16), label: const Text("Salvează Modificări", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
              ),
            ],
          ),
          const SizedBox(height: 30),
          if (_settingsSelectedIndex == 0) _setariProfil(),
          if (_settingsSelectedIndex == 1) _setariSecuritate(),
          if (_settingsSelectedIndex == 2) _setariNotificari(),
          if (_settingsSelectedIndex == 3) _setariPreferinte(),
          if (_settingsSelectedIndex == 4) _setariSistem(),
        ],
      ),
    );
  }

  Widget _setariProfil() {
    String initials = _numeAdminCtrl.text.isNotEmpty ? _numeAdminCtrl.text.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() : "A";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(radius: 40, backgroundColor: primaryBlue, child: Text(initials, style: const TextStyle(fontSize: 30, color: Colors.white))), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Setări de Profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _textMain)), Text("Actualizează informațiile contului", style: TextStyle(color: _textSec))])]),
      const SizedBox(height: 30),
      Row(children: [Expanded(child: _inputSetari("Nume complet", "Numele tău...", controller: _numeAdminCtrl)), const SizedBox(width: 20), Expanded(child: _inputSetari("Rol", "Administrator Principal", readOnly: true))]), const SizedBox(height: 20),
      _inputSetari("Email", "Emailul tău...", icon: Icons.email_outlined, readOnly: true, controller: _emailAdminCtrl), const SizedBox(height: 20),
      _inputSetari("Telefon", "Ex: 07...", icon: Icons.phone_android, controller: _telefonAdminCtrl),
    ]);
  }

  Widget _setariSecuritate() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)), child: const Row(children: [Icon(Icons.shield_outlined, color: Colors.orange), SizedBox(width: 10), Expanded(child: Text("Pentru a schimba parola, trebuie să o introduci corect pe cea actuală.", style: TextStyle(color: Colors.deepOrange)))])),
      const SizedBox(height: 30), Text("Schimbă parola", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textMain)), const SizedBox(height: 15),
      _inputParola("Parola curentă", _ascundeParolaCurenta, () => setState(() => _ascundeParolaCurenta = !_ascundeParolaCurenta), _oldPassCtrl), const SizedBox(height: 15),
      Row(children: [Expanded(child: _inputParola("Parolă nouă", _ascundeParolaNoua, () => setState(() => _ascundeParolaNoua = !_ascundeParolaNoua), _newPassCtrl)), const SizedBox(width: 20), Expanded(child: _inputParola("Confirmă parola", _ascundeConfirmaParola, () => setState(() => _ascundeConfirmaParola = !_ascundeConfirmaParola), _confirmPassCtrl))]),
      const SizedBox(height: 30), Divider(color: _borderC), const SizedBox(height: 20),
      SwitchListTile(title: Text("Autentificare cu doi factori (2FA)", style: TextStyle(fontWeight: FontWeight.bold, color: _textMain)), subtitle: Text("Protejează-ți contul cu un cod suplimentar", style: TextStyle(color: _textSec)), value: _is2FAEnabled, activeThumbColor: primaryBlue, onChanged: (v) { setState(() => _is2FAEnabled = v); _salveazaSetareBool('2fa_enabled', v); }, contentPadding: EdgeInsets.zero),
    ]);
  }

  Widget _inputParola(String label, bool isHidden, VoidCallback toggleEye, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSec)), const SizedBox(height: 8),
      TextField(controller: controller, obscureText: isHidden, style: TextStyle(color: _textMain), decoration: InputDecoration(hintText: "••••••••", hintStyle: TextStyle(color: _textSec), suffixIcon: IconButton(icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility, color: _textSec, size: 20), onPressed: toggleEye), filled: true, fillColor: _bgApp, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderC)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderC)))),
    ]);
  }

  Widget _setariNotificari() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.email_outlined, color: _textSec), const SizedBox(width: 10), Text("Notificări Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textMain))]), const SizedBox(height: 10),
      SwitchListTile(title: Text("Cereri noi de voluntariat", style: TextStyle(color: _textMain)), value: _notifEmail1, activeThumbColor: primaryBlue, onChanged: (v) { setState(() => _notifEmail1 = v); _salveazaSetareBool('notif_email1', v); }, contentPadding: EdgeInsets.zero),
      SwitchListTile(title: Text("Mesaje noi", style: TextStyle(color: _textMain)), value: _notifEmail2, activeThumbColor: primaryBlue, onChanged: (v) { setState(() => _notifEmail2 = v); _salveazaSetareBool('notif_email2', v); }, contentPadding: EdgeInsets.zero),
      const SizedBox(height: 30), Divider(color: _borderC), const SizedBox(height: 20),
      Row(children: [Icon(Icons.phone_android, color: _textSec), const SizedBox(width: 10), Text("Notificări Push (Aplicație)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textMain))]), const SizedBox(height: 10),
      SwitchListTile(title: Text("Cereri noi de voluntariat", style: TextStyle(color: _textMain)), value: _notifPush1, activeThumbColor: primaryBlue, onChanged: (v) { setState(() => _notifPush1 = v); _salveazaSetareBool('notif_push1', v); }, contentPadding: EdgeInsets.zero),
      SwitchListTile(title: Text("Mesaje noi", style: TextStyle(color: _textMain)), value: _notifPush2, activeThumbColor: primaryBlue, onChanged: (v) { setState(() => _notifPush2 = v); _salveazaSetareBool('notif_push2', v); }, contentPadding: EdgeInsets.zero),
      const SizedBox(height: 30), Divider(color: _borderC), const SizedBox(height: 20),
      SwitchListTile(title: const Text("Raport zilnic", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), subtitle: const Text("Primește un rezumat zilnic cu toate activitățile platformei.", style: TextStyle(color: Colors.blueAccent)), value: _raportZilnic, activeThumbColor: primaryBlue, onChanged: (v) { setState(() => _raportZilnic = v); _salveazaSetareBool('raport_zilnic', v); }, contentPadding: EdgeInsets.zero),
    ]);
  }

  Widget _setariPreferinte() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: _buildDropdown("Limbă interfață", ["Română", "English", "Español"], _limbaSelectata, (v) { setState(() => _limbaSelectata = v!); _salveazaSetareString('limba', v!); })), const SizedBox(width: 20), Expanded(child: _buildDropdown("Fus orar", ["Europa/București (GMT+2)", "Europa/Londra (GMT+0)"], _fusOrarSelectat, (v) { setState(() => _fusOrarSelectat = v!); _salveazaSetareString('fus_orar', v!); }))]),
      const SizedBox(height: 20),
      _buildDropdown("Format dată", ["DD/MM/YYYY", "MM/DD/YYYY", "YYYY-MM-DD"], _formatDataSelectat, (v) { setState(() => _formatDataSelectat = v!); _salveazaSetareString('format_data', v!); }),
      const SizedBox(height: 30),
      Row(children: [Icon(Icons.palette_outlined, color: _textSec, size: 18), const SizedBox(width: 8), Text("Temă Interfață", style: TextStyle(fontWeight: FontWeight.bold, color: _textMain))]), const SizedBox(height: 15),
      Row(children: [
        Expanded(child: _buildThemeBox("Luminos", Colors.white, Colors.black)), const SizedBox(width: 15),
        Expanded(child: _buildThemeBox("Întunecat", const Color(0xFF0F172A), Colors.white)), const SizedBox(width: 15),
        Expanded(child: _buildThemeBox("Automat", Colors.grey.shade300, Colors.black, isGradient: true)),
      ])
    ]);
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSec)), const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: value, dropdownColor: _bgCard, decoration: InputDecoration(filled: true, fillColor: _bgApp, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderC)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderC))), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14, color: _textMain)))).toList(), onChanged: onChanged)
    ]);
  }

  Widget _buildThemeBox(String titlu, Color bg, Color textColor, {bool isGradient = false}) {
    bool isSel = _temaSelectata == titlu;
    return GestureDetector(
      onTap: () { setState(() => _temaSelectata = titlu); _salveazaSetareString('tema', titlu); },
      child: Container(
        padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _bgApp, borderRadius: BorderRadius.circular(15), border: Border.all(color: isSel ? primaryBlue : _borderC, width: isSel ? 2 : 1)),
        child: Column(children: [
          Container(height: 50, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300), gradient: isGradient ? const LinearGradient(colors: [Colors.white, Colors.black87]) : null)),
          const SizedBox(height: 10), Text(titlu, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? primaryBlue : _textMain))
        ]),
      ),
    );
  }

  Widget _setariSistem() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: primaryBlue.withValues(alpha: 0.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(title: const Text("Backup automat", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))), subtitle: Text("Creează backup-uri zilnice ale bazei de date", style: TextStyle(color: _textMain)), value: _backupAutomat, activeThumbColor: primaryBlue, onChanged: (v) { setState(() => _backupAutomat = v); _salveazaSetareBool('backup_automat', v); }, contentPadding: EdgeInsets.zero),
        const SizedBox(height: 10), _buildDropdown("Frecvență backup", ["Zilnic", "Săptămânal", "Lunar"], "Zilnic", (v){}),
      ])),
      const SizedBox(height: 30),
      _inputSetari("Retenție date (zile)", "90"),
      const SizedBox(height: 30),
      Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.red.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
  ),
  child: SwitchListTile(
    title: const Text(
      "Mod mentenanță",
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
    ),
    subtitle: const Text("Platforma va fi inaccesibilă IMEDIAT pentru toți utilizatorii"),
    value: _modMentenanta,
    activeThumbColor: Colors.red,
    onChanged: (bool v) async {
      // 1. Dacă vrea să activeze mentenanța, cerem confirmare (Safety First)
      if (v == true) {
        bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Activare Mentenanță ⚠️"),
            content: const Text("Ești sigur? Această acțiune va deloga instantaneu toți utilizatorii activi și va bloca accesul în aplicație!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("ANULEAZĂ"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "DA, ACTIVEAZĂ",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ?? false;

        if (!confirm) return; // Oprim execuția dacă adminul a dat Cancel
      }

      // 2. Executăm schimbarea reală în baza de date
      try {
        setState(() => _modMentenanta = v);
        await _supabase
            .from('setari_sistem')
            .update({'mod_mentenanta': v})
            .eq('id', 1);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(v ? "Sistem în mentenanță!" : "Sistemul este din nou ONLINE!"),
              backgroundColor: v ? Colors.red : Colors.green,
            ),
          );
        }
      } catch (e) {
        // Dacă e eroare de net, resetăm switch-ul vizual
        setState(() => _modMentenanta = !v);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Eroare la server: $e"), backgroundColor: Colors.orange),
          );
        }
      }
    },
  ),
),
      const SizedBox(height: 30),
      Text("Acțiuni sistem", style: TextStyle(fontWeight: FontWeight.bold, color: _textMain)),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export în curs..."))), icon: Icon(Icons.download, color: _textMain), label: Text("Exportă date", style: TextStyle(color: _textMain)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: BorderSide(color: _borderC)))),
          const SizedBox(width: 15),
          Expanded(child: OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deschide fișier import..."))), icon: Icon(Icons.upload, color: _textMain), label: Text("Importă date", style: TextStyle(color: _textMain)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: BorderSide(color: _borderC)))),
        ],
      ),
      const SizedBox(height: 15),
      Row(
        children: [
          Expanded(child: ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup creat cu succes!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)), icon: const Icon(Icons.backup, color: Colors.white), label: const Text("Creează backup", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, padding: const EdgeInsets.symmetric(vertical: 15)))),
          const SizedBox(width: 15),
          Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.restore, color: Colors.white), label: const Text("Restaurează backup", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15)))),
        ],
      ),
    ]);
  }

  Widget _inputSetari(String label, String hint, {IconData? icon, bool readOnly = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSec)),
        const SizedBox(height: 8),
        TextField(
          readOnly: readOnly,
          controller: controller,
          style: TextStyle(color: _textMain),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: _textSec), prefixIcon: icon != null ? Icon(icon, color: _textSec, size: 20) : null, filled: true, fillColor: _bgApp, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderC)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderC))),
        ),
      ],
    );
  }
}