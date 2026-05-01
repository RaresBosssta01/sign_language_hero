import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _supabase = Supabase.instance.client;
  
  String _tipSelectat = 'medical';
  DateTime? _dataSelectata;
  TimeOfDay? _oraSelectata;
  final TextEditingController _adresaController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  bool _seIncarca = false;

  Future<Map<String, double>?> _obtineCoordonateGps(String adresa) async {
    try {
      final query = Uri.encodeComponent(adresa);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      
      final request = await HttpClient().getUrl(url);
      request.headers.set('User-Agent', 'SignLanguageHeroApp/1.0');
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        final List<dynamic> json = jsonDecode(stringData);
        
        if (json.isNotEmpty) {
          return {
            'lat': double.parse(json[0]['lat'].toString()),
            'lng': double.parse(json[0]['lon'].toString()),
          };
        }
      }
    } catch (e) {
      debugPrint("Eroare la Geocoding: $e");
    }
    return null; 
  }

  Future<void> _trimiteCererea() async {
    if (_dataSelectata == null || _oraSelectata == null || _adresaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Te rugăm să completezi Data, Ora și Adresa!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

 
    final dataFinala = DateTime(
      _dataSelectata!.year, _dataSelectata!.month, _dataSelectata!.day,
      _oraSelectata!.hour, _oraSelectata!.minute,
    );


    final limitTime = DateTime.now().add(const Duration(minutes: 15));
    if (dataFinala.isBefore(limitTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Programarea trebuie făcută cu cel puțin 15 minute în avans!"), 
          backgroundColor: Colors.orange,
        ),
      );
      return; 
    }

    setState(() => _seIncarca = true);

    try {
      final idUtilizator = _supabase.auth.currentUser!.id;


      Map<String, double>? coordonate = await _obtineCoordonateGps(_adresaController.text.trim());
      

      if (coordonate == null) {
        final profilData = await _supabase.from('profiluri').select('lat, lng').eq('id', idUtilizator).single();
        if (profilData['lat'] != null && profilData['lng'] != null) {
          coordonate = {
            'lat': double.parse(profilData['lat'].toString()),
            'lng': double.parse(profilData['lng'].toString())
          };
        } else {
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Nu am putut găsi adresa. Te rugăm să fii mai specific (ex: Oraș, Stradă)."), backgroundColor: Colors.orange),
           );
           setState(() => _seIncarca = false); 
           return; 
        }
      }


      final dataFinalaIso = dataFinala.toLocal().toIso8601String();

   
      String titlu;
      if (_tipSelectat == 'medical') titlu = "Consultație Medicală";
      else if (_tipSelectat == 'primarie') titlu = "Întâlnire Instituții/Primărie";
      else if (_tipSelectat == 'video') titlu = "Apel Video Urgent";
      else titlu = "Asistență Generală";


      await _supabase.from('programari').insert({
        'utilizator_id': idUtilizator, 
        'titlu': titlu,
        'subtitlu': 'Se caută voluntar...',
        'tip_icoana': _tipSelectat,
        'data_ora': dataFinalaIso,
        'durata_minute': 60,
        'locatie_nume': 'Locație fixată pe hartă',
        'locatie_adresa': _adresaController.text.trim(),
        'nota_importanta': _notaController.text.trim(),
        'status': 'în așteptare',
        'lat': coordonate['lat'],
        'lng': coordonate['lng'], 
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Cererea a fost trimisă voluntarilor din zonă!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _seIncarca = false);
    }
  }

  Future<void> _alegeData() async {
    final aleasa = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (aleasa != null) setState(() => _dataSelectata = aleasa);
  }

  Future<void> _alegeOra() async {
    final aleasa = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (aleasa != null) setState(() => _oraSelectata = aleasa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Solicită un Interpret", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _seIncarca 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF6366F1)),
                const SizedBox(height: 20),
                Text("Localizăm adresa pe hartă...", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              ],
            )
          ) 
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pentru ce ai nevoie de ajutor?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(child: _buildCategorieCard('medical', "Spital / Medic", Icons.medical_information, const Color(0xFF10B981))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCategorieCard('primarie', "Instituții", Icons.account_balance, const Color(0xFFA855F7))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildCategorieCard('video', "Apel Video", Icons.videocam, const Color(0xFF3B82F6))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCategorieCard('info', "Altele", Icons.help_outline, Colors.orange)),
                ],
              ),

              const SizedBox(height: 30),
              const Text("Când are loc?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),

  
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _alegeData,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF6366F1)), const SizedBox(width: 10),
                            Expanded(child: Text(_dataSelectata == null ? "Alege Data" : "${_dataSelectata!.day}/${_dataSelectata!.month}/${_dataSelectata!.year}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _alegeOra,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF6366F1)), const SizedBox(width: 10),
                            Expanded(child: Text(
              
                              _oraSelectata == null ? "Alege Ora" : "${_oraSelectata!.hour.toString().padLeft(2, '0')}:${_oraSelectata!.minute.toString().padLeft(2, '0')}", 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), 
                              overflow: TextOverflow.ellipsis
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Text("Unde ne vedem?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),

          
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                child: TextField(
                  controller: _adresaController,
                  textInputAction: TextInputAction.next, 
                  decoration: const InputDecoration(
                    hintText: "Ex: București, Strada Calea Floreasca 8",
                    prefixIcon: Icon(Icons.location_on, color: Color(0xFF10B981)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text("Detalii suplimentare (Opțional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),


              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                child: TextField(
                  controller: _notaController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: "Scrie aici dacă ai nevoie de un interpret pentru un anumit dialect sau detalii specifice...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),

              const SizedBox(height: 40),

  
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _trimiteCererea,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("LANSEAZĂ CEREREA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
      ),
    );
  }


  Widget _buildCategorieCard(String id, String titlu, IconData icon, Color color) {
    bool isSelected = _tipSelectat == id;
    return GestureDetector(
      onTap: () => setState(() => _tipSelectat = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white, 
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 10),
            Text(titlu, style: TextStyle(color: isSelected ? color : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}