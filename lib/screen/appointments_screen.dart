import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentsScreen extends StatefulWidget {
  final String rol;
  const AppointmentsScreen({super.key, required this.rol});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _supabase = Supabase.instance.client;
  late String myId;

  @override
  void initState() {
    super.initState();
    myId = _supabase.auth.currentUser!.id;
  }

  Future<String> _obtineNumePartener(String id) async {
    try {
      final data = await _supabase
          .from('profiluri')
          .select('prenume, nume') 
          .eq('id', id)
          .single();
          
      return "${data['prenume']} ${data['nume']}";
    } catch (e) {
      return "Utilizator necunoscut";
    }
  }

  Future<void> _acceptaCererea(String cerereId) async {
    try {
      await _supabase.from('programari').update({
        'voluntar_id': myId,
        'status': 'confirmat'
      }).eq('id', cerereId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Ai preluat cererea cu succes! O găsești la Programările Mele."), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare la preluare: $e"), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _finalizeazaProgramarea(String programareId, String voluntarId) async {
    try {
      await _supabase.from('programari').update({
        'status': 'finalizata'
      }).eq('id', programareId);

      final profilData = await _supabase.from('profiluri').select('xp').eq('id', voluntarId).maybeSingle();
      int xpCurent = 0;
      if (profilData != null && profilData['xp'] != null) {
        xpCurent = int.tryParse(profilData['xp'].toString()) ?? 0;
      }
      
      int xpNou = xpCurent + 50;
      await _supabase.from('profiluri').update({
        'xp': xpNou
      }).eq('id', voluntarId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Întâlnire finalizată cu succes! Ai primit +50 XP."), 
          backgroundColor: Color(0xFF10B981)
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Eroare la finalizare: $e"), backgroundColor: Colors.redAccent)
      );
    }
  }

  Future<void> _acordaRating(String programareId, String voluntarId, int stele) async {
    try {
      final voluntarData = await _supabase.from('profiluri').select('rating, numar_ratinguri').eq('id', voluntarId).single();
      
      double ratingCurent = double.tryParse(voluntarData['rating']?.toString() ?? '5.0') ?? 5.0;
      int numarCurent = voluntarData['numar_ratinguri'] ?? 0;

      int numarNou = numarCurent + 1;
      double ratingNou = ((ratingCurent * numarCurent) + stele) / numarNou;
      
      ratingNou = double.parse(ratingNou.toStringAsFixed(1));

      await _supabase.from('profiluri').update({
        'rating': ratingNou,
        'numar_ratinguri': numarNou
      }).eq('id', voluntarId);

      await _supabase.from('programari').update({
        'status': 'evaluata' 
      }).eq('id', programareId);

      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mulțumim pentru feedback! Rating salvat cu succes."), backgroundColor: Colors.green)
      );

    } catch (e) {
      debugPrint("Eroare la acordarea ratingului: $e");
    }
  }

  void _arataDialogRating(Map<String, dynamic> appointment) {
    int steleSelectate = 5; 

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(25),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
                ),
                const SizedBox(height: 20),
                const Text("Cum a fost experiența?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                const Text("Oferă o notă voluntarului tău pentru a menține calitatea comunității.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 25),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setModalState(() => steleSelectate = index + 1);
                      },
                      icon: Icon(
                        index < steleSelectate ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 35,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0
                    ),
                    onPressed: () => _acordaRating(appointment['id'].toString(), appointment['voluntar_id'].toString(), steleSelectate),
                    child: const Text("TRIMITE RATING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _supabase.from('programari').update({'status': 'evaluata'}).eq('id', appointment['id']);
                    Navigator.pop(context);
                  },
                  child: const Text("Omite", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          );
        }
      )
    );
  }

  Future<void> _deschideAplicatie(String tip, String partenerId) async {
    try {
      final partenerData = await _supabase.from('profiluri').select('telefon, email').eq('id', partenerId).single();
      
      String numarTelefon = partenerData['telefon'] ?? "";
      String adresaEmail = partenerData['email'] ?? "";

      if (tip == 'sms' && numarTelefon.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilizatorul nu are număr de telefon salvat.")));
        return;
      }

      if (tip == 'email' && adresaEmail.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilizatorul nu are email salvat.")));
        return;
      }

      final Uri uri = tip == 'sms' 
          ? Uri(scheme: 'sms', path: numarTelefon)
          : Uri(scheme: 'mailto', path: adresaEmail, query: 'subject=Referitor la programarea Sign Language Hero');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nu am putut deschide aplicația.")));
      }
    } catch (e) {
      debugPrint("Eroare la contactare: $e");
    }
  }

  Future<void> _deschideHarta(String adresa) async {
    if (adresa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adresa nu este specificată.")));
      return;
    }
    
    final String urlCodificat = Uri.encodeComponent(adresa);
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$urlCodificat");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nu am putut deschide harta.")));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String _formateazaData(String dataIso) {
    try {
      DateTime dt = DateTime.parse(dataIso).toLocal();
      List<String> zile = ["", "luni", "marți", "miercuri", "joi", "vineri", "sâmbătă", "duminică"];
      List<String> luni = ["", "ianuarie", "februarie", "martie", "aprilie", "mai", "iunie", "iulie", "august", "septembrie", "octombrie", "noiembrie", "decembrie"];
      return "${zile[dt.weekday]}, ${dt.day} ${luni[dt.month]} ${dt.year}";
    } catch (e) { return "Dată invalidă"; }
  }

  String _formateazaOra(String dataIso) {
    try {
      DateTime dt = DateTime.parse(dataIso).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) { return "--:--"; }
  }

  @override
  Widget build(BuildContext context) {
    bool isVoluntar = widget.rol == 'voluntar';

    return DefaultTabController(
      length: isVoluntar ? 2 : 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB), 
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text("Programări", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: isVoluntar 
            ? const TabBar(
                labelColor: Color(0xFF6366F1),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF6366F1),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Programările Mele"),
                  Tab(text: "Cereri Noi"),
                ],
              )
            : null,
        ),
        body: TabBarView(
          physics: isVoluntar ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          children: [
            _buildStreamList(isMarketplace: false),
            
            if (isVoluntar)
              _buildStreamList(isMarketplace: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamList({required bool isMarketplace}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('programari').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var toateProgramarile = List<Map<String, dynamic>>.from(snapshot.data ?? []);
        bool isVoluntar = widget.rol == 'voluntar';
        
        toateProgramarile.sort((a, b) {
          final dateA = DateTime.tryParse(a['data_ora'].toString()) ?? DateTime.now();
          final dateB = DateTime.tryParse(b['data_ora'].toString()) ?? DateTime.now();
          return dateA.compareTo(dateB); 
        });

        var programari = <Map<String, dynamic>>[];
        
        if (isMarketplace) {
          programari = toateProgramarile.where((p) => p['voluntar_id'] == null && p['status'] == 'în așteptare').toList();
        } else {
          String campFiltru = isVoluntar ? 'voluntar_id' : 'utilizator_id';
          
          programari = toateProgramarile.where((p) {
            if (p[campFiltru] != myId) return false;
            
            if (p['status'] == 'anulata') return false; 
            if (p['status'] == 'evaluata') return false; 
            
            if (isVoluntar && p['status'] == 'finalizata') return false; 
            
            return true;
          }).toList();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 40),
          itemCount: programari.isEmpty ? 1 : programari.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeaderExact(programari.length, isMarketplace);
            }
            
            if (programari.isEmpty) {
              return _buildEmptyState(isMarketplace);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: _buildAppointmentCardExact(programari[index - 1], isMarketplace),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderExact(int count, bool isMarketplace) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF6366F1), width: 2), 
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isMarketplace ? Colors.orange : const Color(0xFF6366F1), shape: BoxShape.circle),
            child: Icon(isMarketplace ? Icons.radar : Icons.calendar_month_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMarketplace ? "Cereri în Așteptare" : "Programările Mele", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 5),
                          Text(_formateazaData(DateTime.now().toIso8601String()).split(', ')[1], style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: isMarketplace ? Colors.orange.shade50 : const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(isMarketplace ? Icons.priority_high : Icons.check, size: 12, color: isMarketplace ? Colors.orange.shade800 : const Color(0xFF16A34A)),
                          const SizedBox(width: 5),
                          Text("$count Găsite", style: TextStyle(fontSize: 12, color: isMarketplace ? Colors.orange.shade800 : const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAppointmentCardExact(Map<String, dynamic> appointment, bool isMarketplace) {
    String status = appointment['status'] ?? 'în așteptare';
    String tipIcoana = appointment['tip_icoana'] ?? 'info';
    String titlu = appointment['titlu'] ?? 'Întâlnire';
    String durata = "${appointment['durata_minute'] ?? 30} min";
    String locatieNume = appointment['locatie_nume'] ?? 'Locație nespecificată';
    String locatieAdresa = appointment['locatie_adresa'] ?? '';
    List<dynamic> participanti = appointment['participanti'] ?? [];
    String nota = appointment['nota_importanta'] ?? '';

    bool isVoluntar = widget.rol == 'voluntar';

    String? partenerId;
    if (isMarketplace) {
      partenerId = appointment['utilizator_id'];
    } else {
      partenerId = isVoluntar ? appointment['utilizator_id'] : appointment['voluntar_id'];
    }

    Color themeColor;
    IconData mainIcon;
    if (tipIcoana == 'medical') {
      themeColor = const Color(0xFF10B981);
      mainIcon = Icons.medical_information;
    } else if (tipIcoana == 'video') {
      themeColor = const Color(0xFF3B82F6);
      mainIcon = Icons.videocam_rounded;
    } else {
      themeColor = const Color(0xFFA855F7); 
      mainIcon = Icons.people_alt_rounded;
    }

    bool isPending = status == 'în așteptare';
    Color statusColor = isPending ? const Color(0xFFEAB308) : const Color(0xFF10B981);
    IconData statusIcon = isPending ? Icons.access_time : Icons.check;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Container(height: 8, color: themeColor),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 5),
                            Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                          ],
                        ),
                      ),
                      if (!isMarketplace && status != 'finalizata') 
                        GestureDetector(
                          onTap: () => _dialogAnulareAvansat(appointment),
                          child: const Text("Anulează", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(12)),
                        child: Icon(mainIcon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titlu, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 2),
                            if (partenerId == null)
                              const Text("În așteptarea unui voluntar...", style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w600))
                            else
                              FutureBuilder<String>(
                                future: _obtineNumePartener(partenerId),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? "Se caută persoana...",
                                    style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                                  );
                                },
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle), child: const Icon(Icons.access_time, color: Colors.white, size: 16)),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("ORA", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(_formateazaOra(appointment['data_ora']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                            ])
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFC7D2FE))),
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle), child: const Icon(Icons.calendar_month, color: Colors.white, size: 16)),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("DATA", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(_formateazaData(appointment['data_ora']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3730A3))),
                            ])
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFC7D2FE))),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text("Durată: $durata", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle), child: const Icon(Icons.location_on, color: Colors.white, size: 14)),
                            const SizedBox(width: 10),
                            const Text("LOCAȚIE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(locatieNume, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(tipIcoana == 'video' ? Icons.videocam : Icons.near_me, size: 12, color: const Color(0xFF10B981)),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text(locatieAdresa, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                            onPressed: () => _deschideHarta(locatieAdresa),
                            icon: const Icon(Icons.near_me, color: Colors.white, size: 18),
                            label: const Text("DESCHIDE HARTĂ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        )
                      ],
                    ),
                  ),

                  if (participanti.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF), 
                        border: Border.all(color: const Color(0xFFE9D5FF)), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.people_alt, size: 18, color: Color(0xFFA855F7)),
                              SizedBox(width: 10),
                              Text("PARTICIPANȚI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...participanti.map((nume) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text("• $nume", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          )),
                        ],
                      ),
                    ),
                  ],

                  if (nota.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), border: Border.all(color: const Color(0xFFBFDBFE)), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, size: 24, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("NOTĂ IMPORTANTĂ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                const SizedBox(height: 4),
                                Text(nota, style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  if (isMarketplace) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptaCererea(appointment['id'].toString()),
                        icon: const Icon(Icons.handshake, color: Colors.white),
                        label: const Text("ACCEPTĂ CEREREA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ] else ...[
                    if (partenerId != null)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () => _deschideAplicatie('email', partenerId!),
                                icon: const Icon(Icons.email_outlined, color: Colors.white, size: 18),
                                label: const Text("EMAIL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () => _deschideAplicatie('sms', partenerId!),
                                icon: const Icon(Icons.phone_android, color: Colors.white, size: 18),
                                label: const Text("SMS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    
                    if (isVoluntar && status == 'confirmat' && appointment['voluntar_id'] != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () => _finalizeazaProgramarea(appointment['id'].toString(), appointment['voluntar_id'].toString()),
                          icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                          label: const Text("MARCHEAZĂ CA FINALIZATĂ (+50 XP)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ],

                    if (!isVoluntar && status == 'finalizata') ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () => _arataDialogRating(appointment),
                          icon: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                          label: const Text("EVALUEAZĂ VOLUNTARUL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600, 
                            elevation: 0, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                        ),
                      ),
                    ]
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isMarketplace) {
    return Column(
      children: [
        const SizedBox(height: 80),
        Icon(isMarketplace ? Icons.radar_rounded : Icons.event_busy, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        Text(
          isMarketplace ? "Nicio urgență în zonă." : "Nu ai nicio programare activă.", 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)
        ),
      ],
    );
  }

  void _dialogAnulareAvansat(Map<String, dynamic> appointment) {
    final controller = TextEditingController();
    bool isVoluntar = widget.rol == 'voluntar';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(
                  isVoluntar ? Icons.warning_amber_rounded : Icons.cancel_presentation_rounded, 
                  color: Colors.redAccent, 
                  size: 40
                ),
              ),
              const SizedBox(height: 20),
              
              const Text("Anulare Programare", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              Text(
                isVoluntar 
                  ? "Ești sigur? Dacă anulezi, persoana va rămâne fără ajutor, dar cererea se va întoarce la alți voluntari." 
                  : "Ești sigur că vrei să anulezi cererea? Această acțiune este definitivă.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(color: const Color(0xFFF4F7FB), borderRadius: BorderRadius.circular(15)),
                child: TextField(
                  controller: controller,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: "Scrie un motiv scurt...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text("ÎNAPOI", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        String motiv = controller.text.trim().isEmpty ? "Fără motiv specificat" : controller.text.trim();
                        
                        try {
                          if (isVoluntar) {
                            await _supabase.from('programari').update({
                              'status': 'în așteptare',
                              'voluntar_id': null, 
                              'motiv_anulare': 'Voluntar: $motiv'
                            }).eq('id', appointment['id']);
                          } else {
                            await _supabase.from('programari').update({
                              'status': 'anulata',
                              'motiv_anulare': 'Beneficiar: $motiv'
                            }).eq('id', appointment['id']);
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isVoluntar ? "Cererea a fost eliberată pentru alți voluntari." : "Programare anulată cu succes."), 
                              backgroundColor: Colors.orange
                            )
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare: $e"), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}