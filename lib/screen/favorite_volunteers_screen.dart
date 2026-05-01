import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteVolunteersScreen extends StatefulWidget {
  const FavoriteVolunteersScreen({super.key});

  @override
  State<FavoriteVolunteersScreen> createState() => _FavoriteVolunteersScreenState();
}

class _FavoriteVolunteersScreenState extends State<FavoriteVolunteersScreen> {
  final _supabase = Supabase.instance.client;
  late final String myId;

  bool _arataDoarOnline = false;

  @override
  void initState() {
    super.initState();
    myId = _supabase.auth.currentUser!.id;
  }

  Future<void> _stergeDinFavorite(String idInregistrare, String nume) async {
    try {
      await _supabase.from('voluntari_preferati').delete().eq('id', idInregistrare);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$nume a fost scos din lista ta."), 
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {}); 
    } catch (e) {
      debugPrint("Eroare la ștergere: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1, 
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          "Voluntarii Mei", 
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabase.from('voluntari_preferati').select('id, profiluri!voluntar_id(*)').eq('user_id', myId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Eroare la încărcare.", style: TextStyle(color: Colors.red.shade400)));
          }

          List<Map<String, dynamic>> favorite = snapshot.data ?? [];

          if (_arataDoarOnline) {
            favorite = favorite.where((f) {
              final vol = f['profiluri'];
              return vol != null && vol['is_online'] == true;
            }).toList();
          }

          int totalSalvati = snapshot.data?.length ?? 0;
          int totalOnline = snapshot.data?.where((f) => f['profiluri']?['is_online'] == true).length ?? 0;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Text(
                      "Salvați: $totalSalvati", 
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 14)
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _arataDoarOnline = !_arataDoarOnline),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _arataDoarOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _arataDoarOnline ? const Color(0xFFA7F3D0) : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: _arataDoarOnline ? const Color(0xFF10B981) : Colors.grey,
                                shape: BoxShape.circle
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Online ($totalOnline)", 
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                                color: _arataDoarOnline ? const Color(0xFF047857) : const Color(0xFF475569)
                              )
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

              Expanded(
                child: favorite.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: favorite.length,
                        itemBuilder: (context, index) {
                          final inregistrare = favorite[index];
                          final voluntar = inregistrare['profiluri'];
                          
                          if (voluntar == null) return const SizedBox();

                          return _buildVolunteerCard(inregistrare['id'].toString(), voluntar);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVolunteerCard(String idInregistrare, Map<String, dynamic> voluntar) {
    String nume = "${voluntar['prenume']} ${voluntar['nume']}".trim();
    String pozaUrl = voluntar['poza_profil'] ?? '';
    bool isOnline = voluntar['is_online'] ?? false;
    

    List<String> competente = [];
    if (voluntar['interese'] != null && voluntar['interese'].toString().isNotEmpty) {
      competente = voluntar['interese'].split(',').map((e) => e.trim().toString()).toList();
    }

  
    double rating = double.tryParse(voluntar['rating']?.toString() ?? '5.0') ?? 5.0;
    int nrRatinguri = voluntar['numar_ratinguri'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEFF6FF),
                backgroundImage: pozaUrl.isNotEmpty ? NetworkImage(pozaUrl) : null,
                child: pozaUrl.isEmpty 
                    ? Text(nume.isNotEmpty ? nume[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)) 
                    : null,
              ),
              if (isOnline)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nume, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
      
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      nrRatinguri == 0 ? "Nou" : "$rating", 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))
                    ),
                    if (nrRatinguri > 0)
                      Text(
                        " ($nrRatinguri)", 
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))
                      ),
                  ],
                ),
                
                if (competente.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: competente.take(2).map((comp) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6)
                      ),
                      child: Text(
                        comp, 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))
                      ),
                    )).toList(),
                  )
                ]
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deschidere chat...")));
                },
                icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF3B82F6), size: 22),
                tooltip: "Trimite mesaj",
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                onPressed: () => _stergeDinFavorite(idInregistrare, nume),
                icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                tooltip: "Șterge din favorite",
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border_rounded, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          const Text("Lista este goală", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          const Text(
            "Găsește voluntari pe hartă\nși apasă pe inimioară pentru a-i salva.", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), height: 1.5)
          ),
        ],
      ),
    );
  }
}