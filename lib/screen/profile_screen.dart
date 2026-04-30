import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  
  // Cheia globală pentru validarea formularului
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // Variabile pentru datele din baza de date
  String _rol = '';
  String _pozaProfilUrl = '';
  bool _vizibilHarta = true;

  // Controllere pentru formular
  final _prenumeController = TextEditingController();
  final _numeController = TextEditingController();
  final _telefonController = TextEditingController();
  final _adresaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _incarcaDateProfil();
  }

  @override
  void dispose() {
    _prenumeController.dispose();
    _numeController.dispose();
    _telefonController.dispose();
    _adresaController.dispose();
    super.dispose();
  }

  // --- 1. PRELUARE DATE DIN SUPABASE ---
  Future<void> _incarcaDateProfil() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiluri')
          .select('rol, prenume, nume, telefon, adresa_completa, poza_profil, vizibil_harta')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _rol = data['rol'] ?? '';
          _prenumeController.text = data['prenume'] ?? '';
          _numeController.text = data['nume'] ?? '';
          _telefonController.text = data['telefon'] ?? '';
          _adresaController.text = data['adresa_completa'] ?? '';
          _vizibilHarta = data['vizibil_harta'] ?? true;
          _pozaProfilUrl = data['poza_profil'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Eroare încărcare profil: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nu am putut încărca datele."), backgroundColor: Colors.redAccent));
      }
    }
  }

  // --- 2. SALVARE DATE NOI ÎN SUPABASE (CU VALIDĂRI) ---
  Future<void> _salveazaDate() async {
    // Verificăm dacă toate câmpurile respectă regulile
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final noulNume = _numeController.text.trim();
      final noulPrenume = _prenumeController.text.trim();

      await _supabase.from('profiluri').update({
        'prenume': noulPrenume,
        'nume': noulNume,
        'telefon': _telefonController.text.trim(),
        'adresa_completa': _adresaController.text.trim(),
        'vizibil_harta': _vizibilHarta,
        if (!_vizibilHarta) 'is_online': false, // Dispare de pe hartă instant dacă e ghost
      }).eq('id', user.id);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profil actualizat cu succes!"), backgroundColor: Colors.green),
      );
      
      // Trimitem noul nume înapoi către HomeScreen
      Navigator.pop(context, "$noulPrenume $noulNume");
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Eroare la salvare: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- 3. GHOST MODE (Actualizare Instantă în BD) ---
  Future<void> _schimbaGhostMode(bool value) async {
    setState(() => _vizibilHarta = value);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('profiluri').update({
          'vizibil_harta': value,
          if (!value) 'is_online': false 
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint("Eroare Ghost Mode: $e");
      setState(() => _vizibilHarta = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eroare rețea. Nu s-a putut salva setarea."), backgroundColor: Colors.redAccent));
      }
    }
  }

  // --- 4. ÎNCĂRCARE POZĂ DE PROFIL (REPARAT CU CACHE BUSTER) ---
  Future<void> _schimbaPozaProfil() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
      );    

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploadingImage = true);

      final file = File(result.files.single.path!);
      final fileExtension = result.files.single.extension ?? 'jpg';
      final user = _supabase.auth.currentUser;
      
      final fileName = '${user!.id}.$fileExtension';

      // Urcăm poza (suprascriem vechea poză)
      await _supabase.storage.from('avatars').upload(
            fileName,
            file,
            // Setăm cacheControl la 0 ca serverul să nu păstreze fantome
            fileOptions: const FileOptions(cacheControl: '0', upsert: true), 
          );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      
      // HACK-UL GENIAL: Adăugăm milisecundele la URL în baza de date!
      // Asta schimbă textul link-ului, forțând HomeScreen-ul și Profilul să redeseneze poza imediat.
      final urlFinalCuTimestamp = "$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}";

      await _supabase.from('profiluri').update({'poza_profil': urlFinalCuTimestamp}).eq('id', user.id);

      setState(() {
        _pozaProfilUrl = urlFinalCuTimestamp;
        _isUploadingImage = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Poză actualizată!"), backgroundColor: Colors.green));
      
    } catch (e) {
      setState(() => _isUploadingImage = false);
      debugPrint("Eroare upload poză: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare upload: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _rol == 'voluntar' ? const Color(0xFF00796B) : const Color(0xFF0083B0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        title: const Text("Profil & Setări", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: themeColor))
        : SingleChildScrollView(
            child: Form(
              key: _formKey, 
              child: Column(
                children: [
                  // --- HEADER PROFIL (POZA) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 30, top: 20),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _schimbaPozaProfil,
                          child: Stack(
                            children: [
                              Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                                  image: _pozaProfilUrl.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(_pozaProfilUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _pozaProfilUrl.isEmpty
                                    ? Icon(Icons.person, size: 60, color: themeColor.withValues(alpha: 0.5))
                                    : null,
                              ),
                              
                              if (_isUploadingImage)
                                const Positioned.fill(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),

                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(Icons.camera_alt, color: themeColor, size: 20),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "${_prenumeController.text} ${_numeController.text}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _rol.toUpperCase(),
                          style: const TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- FORMULARUL DE SETĂRI ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Date Personale", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 15),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTextField("Prenume", _prenumeController, Icons.person_outline, themeColor, validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Câmp obligatoriu";
                              if (val.trim().length < 2) return "Prea scurt";
                              return null;
                            })),
                            const SizedBox(width: 15),
                            Expanded(child: _buildTextField("Nume", _numeController, Icons.person_outline, themeColor, validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Câmp obligatoriu";
                              if (val.trim().length < 2) return "Prea scurt";
                              return null;
                            })),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        _buildTextField("Telefon", _telefonController, Icons.phone_android, themeColor, isPhone: true, validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Câmp obligatoriu";
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(val.trim())) {
                            return "Exact 10 cifre (fără spații).";
                          }
                          return null;
                        }),
                        const SizedBox(height: 15),

                        _buildTextField("Adresă completă", _adresaController, Icons.location_on_outlined, themeColor, validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Te rugăm să specifici un oraș minim.";
                          return null;
                        }),
                        
                        const SizedBox(height: 30),
                        
                        // --- SETĂRI INTIMITATE (GHOST MODE) ---
                        const Text("Intimitate & Locație", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 15),
                        
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                          ),
                          child: SwitchListTile(
                            title: const Text("Vizibil pe Hartă (Ghost Mode)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              _vizibilHarta 
                                ? "Locația ta este partajată live pentru urgențe." 
                                : "Ești complet ascuns de pe hartă și radar.",
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: _vizibilHarta,
                            activeColor: themeColor,
                            secondary: Icon(
                              _vizibilHarta ? Icons.location_on : Icons.location_off, 
                              color: _vizibilHarta ? themeColor : Colors.grey,
                              size: 28,
                            ),
                            onChanged: _schimbaGhostMode, 
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --- BUTON SALVARE ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _salveazaDate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: _isSaving 
                              ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Salvează Modificările", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, Color themeColor, {bool isPhone = false, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          validator: validator, 
          autovalidateMode: AutovalidateMode.onUserInteraction, 
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: themeColor, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: themeColor, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
          ),
        ),
      ],
    );
  }
}