import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// 1. ECRANUL PRINCIPAL: LISTA DE MESAJE ȘI TAB-URILE
// ============================================================================
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  bool isComunitateTab = false; // False = Personal, True = Comunitate
  String _searchQuery = "";
  late String myId;

  @override
  void initState() {
    super.initState();
    myId = _supabase.auth.currentUser!.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130), 
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF6366F1), 
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Rândul 1: Titlu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Mesaje", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                              SizedBox(width: 5),
                              Text("Online", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                // Rândul 2: Tab-urile Comunitate / Personal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
                    child: Row(
                      children: [
                        _buildTabButton("COMUNITATE", true, 3),
                        _buildTabButton("PERSONAL", false, 4),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Bara de Căutare și Filtre
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(icon: Icon(Icons.search, color: Colors.grey), hintText: "Caută conversații...", border: InputBorder.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meniul de filtrare va fi deschis curând.")));
                        }, 
                        icon: const Icon(Icons.filter_list, size: 16), 
                        label: const Text("Filtrează"), 
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, side: BorderSide(color: Colors.grey.shade300))
                      )
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Afișăm conversațiile fixate...")));
                        }, 
                        icon: const Icon(Icons.push_pin_outlined, size: 16), 
                        label: const Text("Fixate"), 
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black87, side: BorderSide(color: Colors.grey.shade300))
                      )
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // Lista Principală (Se schimbă în funcție de Tab-ul selectat)
          Expanded(
            child: isComunitateTab ? _buildCommunityGroups() : _buildPersonalChats(),
          ),
        ],
      ),
    );
  }

  // --- TAB-UL COMUNITATE (Grupuri) ---
  Widget _buildCommunityGroups() {
    final groups = [
      {"titlu": "Grup Comunitate Surditate", "subtitlu": "Maria: Mulțumesc pentru ajutor! 🙏", "icon": Icons.people, "color": Colors.blue},
      {"titlu": "Interpreți Limbaj Semne", "subtitlu": "Interpret disponibil mâine la 14:00", "icon": Icons.sign_language, "color": Colors.purple},
      {"titlu": "Voluntari București", "subtitlu": "Eveniment sâmbăta la 10:00! 🎉", "icon": Icons.favorite, "color": Colors.teal},
    ];

    final filteredGroups = groups.where((g) => g["titlu"].toString().toLowerCase().contains(_searchQuery)).toList();

    return ListView.builder(
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final g = filteredGroups[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: g["color"] as Color, borderRadius: BorderRadius.circular(15)),
            child: Icon(g["icon"] as IconData, color: Colors.white),
          ),
          title: Text(g["titlu"].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(g["subtitlu"].toString(), style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.push_pin, color: Colors.grey, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Intri în grupul: ${g["titlu"]}...")));
          },
        );
      },
    );
  }

  // --- TAB-UL PERSONAL ---
  Widget _buildPersonalChats() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('profiluri').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final allProfiles = snapshot.data ?? [];
        
        final myProfile = allProfiles.firstWhere((p) => p['id'] == myId, orElse: () => {});
        final String myRole = myProfile['rol'] ?? 'beneficiar';

        var users = allProfiles.where((p) => p['id'] != myId).toList();

        // Reguli de filtrare bazate pe rol
        if (myRole == 'beneficiar') {
          users = users.where((p) => p['rol'] == 'voluntar').toList();
        } else if (myRole == 'voluntar') {
          users = users.where((p) => p['rol'] == 'beneficiar' || p['rol'] == 'admin').toList();
        }

        if (_searchQuery.isNotEmpty) {
          users = users.where((p) {
            final numeComplet = "${p['prenume'] ?? ''} ${p['nume'] ?? ''}".toLowerCase();
            return numeComplet.contains(_searchQuery);
          }).toList();
        }

        if (users.isEmpty) {
          return const Center(child: Text("Nu a fost găsită nicio conversație.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final String numeComplet = "${user['prenume'] ?? 'Utilizator'} ${user['nume'] ?? ''}";
            
            // Verificăm dacă există proprietatea is_online în tabel, altfel punem false
            final bool isOnline = user.containsKey('is_online') ? user['is_online'] == true : false;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 25, 
                    backgroundColor: Colors.primaries[index % Colors.primaries.length], 
                    child: Text(numeComplet[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ),
                  Positioned(
                    bottom: 0, 
                    right: 0, 
                    child: Container(
                      width: 14, height: 14, 
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey.shade400, 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white, width: 2)
                      )
                    )
                  ),
                ],
              ),
              title: Text(numeComplet, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user['rol']?.toString().toUpperCase() ?? 'MEMBRU', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(partenerId: user['id'], partenerNume: numeComplet)));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTabButton(String text, bool isComunitate, int badgeCount) {
    bool isSelected = isComunitateTab == isComunitate;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isComunitateTab = isComunitate),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isComunitate ? Icons.people_alt : Icons.chat_bubble_outline, color: isSelected ? const Color(0xFF6366F1) : Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(text, style: TextStyle(color: isSelected ? const Color(0xFF6366F1) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                if (badgeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ECRANUL DE CHAT (Conversația Real-Time)
// ============================================================================
class ChatDetailScreen extends StatefulWidget {
  final String partenerId;
  final String partenerNume;

  const ChatDetailScreen({super.key, required this.partenerId, required this.partenerNume});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _mesajController = TextEditingController();
  late String myId;

  @override
  void initState() {
    super.initState();
    myId = _supabase.auth.currentUser!.id;
    _marcheazaMesajeleCaCitite();
  }

  // Setăm mesajele primite ca fiind citite când intrăm în chat
  Future<void> _marcheazaMesajeleCaCitite() async {
    try {
      await _supabase.from('mesaje').update({'citit': true}).match({
        'sender_id': widget.partenerId, // ACUM FOLOSIM SENDER_ID
        'receiver_id': myId,            // ACUM FOLOSIM RECEIVER_ID
        'citit': false
      });
    } catch (e) {
      debugPrint("Eroare marcare citit: $e");
    }
  }

  Future<void> _trimiteMesaj() async {
    final trimiteText = _mesajController.text.trim();
    if (trimiteText.isEmpty) return;

    _mesajController.clear();
    
    try {
      // INSERARE CU NUMELE CORECTE DE COLOANE DIN SCHEMA TA
      await _supabase.from('mesaje').insert({
        'sender_id': myId,
        'receiver_id': widget.partenerId,
        'text': trimiteText,     // Coloana ta originală (NOT NULL 🔹)
        'continut': trimiteText, // Și coloana ta nouă
        'citit': false
      });
    } catch (e) {
      debugPrint("Eroare la trimitere: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare la trimitere: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  String _formateazaOraMesaj(String? timestamp) {
    if (timestamp == null) return "";
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('profiluri').stream(primaryKey: ['id']).eq('id', widget.partenerId),
          builder: (context, snapshot) {
            final profile = snapshot.data?.isNotEmpty == true ? snapshot.data!.first : null;
            final bool isOnline = profile != null && profile.containsKey('is_online') && profile['is_online'] == true;

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(backgroundColor: Colors.orange.shade200, child: Text(widget.partenerNume[0], style: const TextStyle(color: Colors.white))),
                    Positioned(
                      bottom: 0, right: 0, 
                      child: Container(width: 12, height: 12, decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.partenerNume, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(isOnline ? "Online" : "Offline", style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // ZONA DE MESAJE (Live Stream)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('mesaje')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false), 
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Eroare la încărcarea mesajelor"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final toateMesajele = snapshot.data ?? [];
                
                // FOLOSIM ACUM SENDER_ID și RECEIVER_ID PENTRU FILTRARE!
                final conversatiaNoastra = toateMesajele.where((msg) => 
                  (msg['sender_id'] == myId && msg['receiver_id'] == widget.partenerId) ||
                  (msg['sender_id'] == widget.partenerId && msg['receiver_id'] == myId)
                ).toList();

                if (conversatiaNoastra.isEmpty) {
                  return const Center(child: Text("Trimite un mesaj pentru a începe conversația 💬", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true, // Afișează de jos în sus
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  itemCount: conversatiaNoastra.length,
                  itemBuilder: (context, index) {
                    final mesaj = conversatiaNoastra[index];
                    final isMe = mesaj['sender_id'] == myId; // VERIFICARE CORECTĂ

                    return _buildBulaMesaj(mesaj, isMe);
                  },
                );
              },
            ),
          ),
          
          // BARA DE JOS PENTRU SCRIS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.security, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        const Text("Mesajele tale sunt criptate și securizate.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(color: const Color(0xFFF4F7FB), borderRadius: BorderRadius.circular(25)),
                          child: TextField(
                            controller: _mesajController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(hintText: "Scrie un mesaj...", border: InputBorder.none),
                            onSubmitted: (_) => _trimiteMesaj(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF6366F1),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _trimiteMesaj,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Construirea bulei de mesaj
  Widget _buildBulaMesaj(Map<String, dynamic> mesaj, bool isMe) {
    String time = _formateazaOraMesaj(mesaj['created_at']);
    bool isRead = mesaj['citit'] == true;
    
    // Extragem textul din coloana originală 'text' sau fallback pe 'continut'
    String continutText = mesaj['text'] ?? mesaj['continut'] ?? "";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), 
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF8B5CF6) : Colors.white, 
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0), 
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
          ),
          boxShadow: isMe ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(continutText, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                if (isMe) ...[
                  const SizedBox(width: 5),
                  Icon(
                    isRead ? Icons.done_all : Icons.check, 
                    color: isRead ? Colors.blue.shade200 : Colors.white70, 
                    size: 14
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}