import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  int _currentStep = 0; 
  String _rolSelectat = 'beneficiar'; 
  
  bool _isUploading = false;
  bool _isLoading = false; 
  String _numeFisierUrcat = '';

  bool _ascundeParola = true;
  bool _ascundeConfirmaParola = true;

  final _formKey = GlobalKey<FormState>();
  final _prenumeController = TextEditingController();
  final _numeController = TextEditingController();
  final _usernameController = TextEditingController(); 
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _parolaController = TextEditingController();
  final _confirmaParolaController = TextEditingController();
  final _varstaController = TextEditingController();

  String? _sexSelectat;
  String? _prefGenVoluntar;
  String? _prefVarstaVoluntar;

  final _descriereController = TextEditingController();
  final _competenteController = TextEditingController();


  late AnimationController _animCtrlBeneficiar;
  late AnimationController _animCtrlVoluntar;

  @override
  void initState() {
    super.initState();
    _animCtrlBeneficiar = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _animCtrlVoluntar = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrlBeneficiar.dispose();
    _animCtrlVoluntar.dispose();
    _prenumeController.dispose();
    _numeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _parolaController.dispose();
    _confirmaParolaController.dispose();
    _varstaController.dispose();
    _descriereController.dispose();
    _competenteController.dispose();
    super.dispose();
  }

  Future<void> _incarcaDocument() async {
    setState(() => _isUploading = true);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
      if (result != null) {
        setState(() => _numeFisierUrcat = result.files.single.name);
      }
    } catch (e) {
      debugPrint("Eroare la alegerea fișierului: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  bool _isEmailValid(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool _isTelefonValid(String telefon) => RegExp(r'^07\d{8}$').hasMatch(telefon.replaceAll(RegExp(r'\s+'), '')); 
  bool _isParolaPuternica(String parola) => RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(parola);

  Future<void> _creeazaCont() async {
    if (!_formKey.currentState!.validate()) return;

    if (_prenumeController.text.trim().isEmpty || _numeController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _parolaController.text.isEmpty || _varstaController.text.trim().isEmpty) {
      _showError('Te rugăm să completezi toate câmpurile obligatorii!');
      return;
    }

    if (!_isEmailValid(_emailController.text.trim())) { _showError('Adresa de email nu este validă!'); return; }

    int? varsta = int.tryParse(_varstaController.text.trim());
    if (varsta == null || varsta < 10 || varsta > 100) { _showError('Te rugăm să introduci o vârstă validă!'); return; }
    
    if (_rolSelectat == 'voluntar' && varsta < 18) { _showError('Atenție: Voluntarii trebuie să aibă minim 18 ani!'); return; }

    if (_rolSelectat == 'voluntar') {
      if (_telefonController.text.isEmpty) { _showError('Numărul de telefon este obligatoriu pentru voluntari!'); return; }
      if (!_isTelefonValid(_telefonController.text.trim())) { _showError('Numărul de telefon este invalid! (ex: 0712345678)'); return; }
    }

    if (!_isParolaPuternica(_parolaController.text)) { _showError('Parola e prea slabă! Minim 8 caractere, o literă MARE și o cifră.'); return; }
    if (_parolaController.text != _confirmaParolaController.text) { _showError('Parolele nu coincid!'); return; }

    setState(() => _isLoading = true); 

    try {
      final supabase = Supabase.instance.client;
      final existingUser = await supabase.from('profiluri').select().eq('email', _emailController.text.trim()).maybeSingle();

      if (existingUser != null) {
        setState(() => _isLoading = false);
        _showError("Acest Email este deja folosit!");
        return;
      }

      final AuthResponse res = await supabase.auth.signUp(email: _emailController.text.trim(), password: _parolaController.text);
      final String? userId = res.user?.id;

      if (userId != null) {
        await supabase.from('profiluri').insert({
          'id': userId, 
          'email': _emailController.text.trim(),
          'rol': _rolSelectat,
          'prenume': _prenumeController.text.trim(),
          'nume': _numeController.text.trim(),
          'telefon': _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
          'varsta': varsta,
          'descriere': _descriereController.text.trim().isNotEmpty ? _descriereController.text.trim() : null,
          'interese': _competenteController.text.trim().isNotEmpty ? _competenteController.text.trim() : null,
          'status': _rolSelectat == 'voluntar' ? 'pending' : 'aprobat',
          'document': _numeFisierUrcat.isEmpty ? null : _numeFisierUrcat,
        });
      } else {
         throw Exception("Eroare la crearea contului.");
      }

      setState(() => _isLoading = false);

      if (_rolSelectat == 'voluntar') {
        _showPendingDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cont creat cu succes!"), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }

    } on AuthException catch (error) {
      setState(() => _isLoading = false);
      _showError("Eroare: ${error.message}");
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("A apărut o eroare neașteptată!");
      debugPrint(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)))]), 
        backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
      )
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cerere trimisă! ⏳"),
        content: const Text("Contul tău de voluntar este în curs de verificare.\nVei putea să te loghezi imediat ce documentele sunt aprobate."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text("AM ÎNȚELES", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007BFF))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE0F7FA), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutExpo,
            switchOutCurve: Curves.easeInExpo,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              );
            },
            child: _currentStep == 0 ? _buildRoleSelectionScreen() : _buildFormScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionScreen() {
    return SingleChildScrollView(
      key: const ValueKey("RoleSelection"),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0083B0), size: 18),
              label: const Text("Înapoi la Login", style: TextStyle(color: Color(0xFF0083B0), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Cum vrei să te alături?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.2), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Text("Alege rolul care ți se potrivește cel mai bine în comunitatea noastră.", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 40),

      
          GestureDetector(
            onTap: () {
              setState(() { _rolSelectat = 'beneficiar'; _currentStep = 1; });
            },
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFF0083B0).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    bottom: 25, left: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Utilizator", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Vreau să învăț și să fiu ajutat", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animCtrlBeneficiar,
                    builder: (context, child) {
                      final wave = math.sin(_animCtrlBeneficiar.value * 2 * math.pi);
                      return Stack(
                        children: [
                          Positioned(right: 40, top: 30 + (wave * 10), child: const Text("🙋‍♂️", style: TextStyle(fontSize: 60))),
                          Positioned(right: 90, top: 60 - (wave * 15), child: Transform.rotate(angle: wave * 0.2, child: const Text("🤟", style: TextStyle(fontSize: 45)))),
                        ],
                      );
                    },
                  ),
                  const Positioned(top: 20, right: 20, child: Icon(Icons.arrow_forward_rounded, color: Colors.white54, size: 30)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),

       
          GestureDetector(
            onTap: () {
              setState(() { _rolSelectat = 'voluntar'; _currentStep = 1; });
            },
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E6B8), Color(0xFF00796B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: const Color(0xFF009688).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    bottom: 25, left: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Voluntar", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Vreau să ajut comunitatea", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animCtrlVoluntar,
                    builder: (context, child) {
                      final wave = math.sin(_animCtrlVoluntar.value * 2 * math.pi);
                      return Stack(
                        children: [
                          Positioned(right: 50, top: 30 - (wave * 15), child: const Text("🦸‍♂️", style: TextStyle(fontSize: 65))),
                          Positioned(right: 120, top: 40 + (wave * 8), child: Transform.rotate(angle: -0.2, child: const Text("🛡️", style: TextStyle(fontSize: 35)))),
                        ],
                      );
                    },
                  ),
                  const Positioned(top: 20, right: 20, child: Icon(Icons.arrow_forward_rounded, color: Colors.white54, size: 30)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormScreen() {
    bool isVoluntar = _rolSelectat == 'voluntar';
    Color themeColor = isVoluntar ? const Color(0xFF00796B) : const Color(0xFF0083B0);
    Color lightThemeColor = isVoluntar ? const Color(0xFF00E6B8) : const Color(0xFF00B4DB);

    return SingleChildScrollView(
      key: const ValueKey("FormScreen"),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentStep = 0),
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeColor),
              ),
              Expanded(
                child: Text(
                  isVoluntar ? "Cont Voluntar" : "Cont Utilizator", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), 
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildInputField(label: "Prenume", hint: "Ion", icon: Icons.person_outline, controller: _prenumeController, activeColor: themeColor)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildInputField(label: "Nume", hint: "Popescu", icon: Icons.person_outline, controller: _numeController, activeColor: themeColor)),
                    ],
                  ),

                  _buildInputField(label: "Username", hint: "ionpopescu", icon: Icons.alternate_email, controller: _usernameController, activeColor: themeColor),
                  _buildInputField(label: "Email", hint: "ion@example.com", icon: Icons.mail_outline, controller: _emailController, activeColor: themeColor),
                  
                  if (isVoluntar)
                     _buildInputField(label: "Număr Telefon (Obligatoriu)", hint: "07xx xxx xxx", icon: Icons.phone_android, controller: _telefonController, isNumber: true, activeColor: themeColor),

                  _buildInputField(
                    label: "Parolă", hint: "••••••••", icon: Icons.lock_outline, isPassword: true, 
                    obscureText: _ascundeParola, onToggleVisibility: () => setState(() => _ascundeParola = !_ascundeParola), controller: _parolaController, activeColor: themeColor
                  ),
                  _buildInputField(
                    label: "Confirmă parola", hint: "••••••••", icon: Icons.lock_outline, isPassword: true, 
                    obscureText: _ascundeConfirmaParola, onToggleVisibility: () => setState(() => _ascundeConfirmaParola = !_ascundeConfirmaParola), controller: _confirmaParolaController, activeColor: themeColor
                  ),
                  
                  Row(
                    children: [
                      Expanded(child: _buildDropdown(label: "Sex", items: ['Masculin', 'Feminin', 'Altul'], value: _sexSelectat, onChanged: (v) => setState(() => _sexSelectat = v), activeColor: themeColor)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildInputField(label: "Vârstă", hint: "Ex: 25", icon: Icons.cake_outlined, controller: _varstaController, isNumber: true, activeColor: themeColor)),
                    ],
                  ),

                  if (!isVoluntar) ...[
                    Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Divider(color: themeColor.withValues(alpha: 0.2), thickness: 1)),
                    Text("Preferințe Voluntar", style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown(label: "Gen preferat", items: ['Indiferent', 'Masculin', 'Feminin'], value: _prefGenVoluntar, onChanged: (v) => setState(() => _prefGenVoluntar = v), activeColor: themeColor)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildDropdown(label: "Vârstă", items: ['Indiferent', 'Tânăr (<30)', 'Adult (30-50)', 'Senior (>50)'], value: _prefVarstaVoluntar, onChanged: (v) => setState(() => _prefVarstaVoluntar = v), activeColor: themeColor)),
                      ],
                    ),
                  ],

                  if (isVoluntar) ...[
                    Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Divider(color: themeColor.withValues(alpha: 0.2), thickness: 1)),
                    Text("Profil Voluntar", style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 16)),
                    const SizedBox(height: 10),
                    _buildInputField(label: "Despre tine (Opțional)", hint: "Sunt pasionat de...", icon: Icons.info_outline, controller: _descriereController, maxLines: 3, activeColor: themeColor, isOptional: true),
                    _buildInputField(label: "Alte competențe (Opțional)", hint: "Ex: Prim ajutor", icon: Icons.star_border_rounded, controller: _competenteController, activeColor: themeColor, isOptional: true),
                    
                    const SizedBox(height: 10),
                    const Text("Documente Oficiale", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _incarcaDocument,
                        icon: _isUploading ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.upload_file, color: _numeFisierUrcat.isEmpty ? Colors.grey : themeColor),
                        label: Text(_numeFisierUrcat.isEmpty ? "Încarcă CV / Certificat (PDF)" : "Atașat: $_numeFisierUrcat", style: TextStyle(color: _numeFisierUrcat.isEmpty ? Colors.grey : Colors.black87)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          side: BorderSide(color: _numeFisierUrcat.isEmpty ? Colors.grey.shade300 : themeColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity, height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [lightThemeColor, themeColor]),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _creeazaCont,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: _isLoading 
                            ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text("Finalizează Înregistrarea →", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

  Widget _buildInputField({
    required String label, required String hint, required IconData icon, required TextEditingController controller, 
    required Color activeColor, bool isPassword = false, bool isNumber = false, int maxLines = 1, bool obscureText = false, VoidCallback? onToggleVisibility, 
    bool isOptional = false 
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller, obscureText: isPassword ? obscureText : false, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: isPassword ? 1 : maxLines,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(color: Colors.black26),
              prefixIcon: maxLines == 1 ? Icon(icon, color: activeColor) : null,
              suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20), onPressed: onToggleVisibility) : null,
              filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: activeColor, width: 2)),
            ),
            validator: (value) {
              if (isOptional) return null; 
              return (value == null || value.isEmpty) ? 'Obligatoriu' : null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required List<String> items, required String? value, required Function(String?) onChanged, required Color activeColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: value, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: activeColor, width: 2)),
            ),
            items: items.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}