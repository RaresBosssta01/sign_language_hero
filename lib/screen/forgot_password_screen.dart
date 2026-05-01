import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _linkTrimis = false;
  bool _modActualizare = false; 
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        setState(() => _modActualizare = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _trimiteLinkResetare() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _arataMesaj("Te rugăm să introduci o adresă de email validă.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.signlanguagehero://reset-callback/', 
      );
      setState(() => _linkTrimis = true);
      _arataMesaj("Link-ul de resetare a fost trimis pe email!", Colors.green);
    } catch (e) {
      _arataMesaj("Eroare: ${e.toString()}", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _actualizeazaParola() async {
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (pass.length < 6) {
      _arataMesaj("Parola trebuie să aibă minim 6 caractere.", Colors.orange);
      return;
    }
    if (pass != confirmPass) {
      _arataMesaj("Parolele nu coincid.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: pass));
      _arataMesaj("Parola a fost actualizată! Te poți loga.", Colors.green);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _arataMesaj("Eroare la actualizare: ${e.toString()}", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _arataMesaj(String text, Color culoare) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: culoare, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black87)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_modActualizare ? Icons.lock_reset_rounded : Icons.mark_email_read_outlined, size: 60, color: const Color(0xFF6366F1)),
              ),
              const SizedBox(height: 30),
              Text(
                _modActualizare ? "Setează Parola Nouă" : "Recuperare Parolă",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Text(
                _modActualizare 
                  ? "Introdu noua ta parolă de acces." 
                  : "Îți vom trimite un link de resetare pe adresa de email.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),

              if (!_modActualizare) ...[
                _buildTextField(
                  controller: _emailController,
                  hint: "Adresa de email",
                  icon: Icons.email_outlined,
                  enabled: !_linkTrimis,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading || _linkTrimis ? null : _trimiteLinkResetare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(_linkTrimis ? "LINK TRIMIS" : "TRIMITE LINK", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                _buildTextField(
                  controller: _passwordController,
                  hint: "Parola nouă",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: "Confirmă parola nouă",
                  icon: Icons.lock_reset_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _actualizeazaParola,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("ACTUALIZEAZĂ PAROLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              
              if (_linkTrimis && !_modActualizare)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: TextButton(
                    onPressed: () => setState(() => _linkTrimis = false),
                    child: const Text("Nu ai primit? Reîncearcă", style: TextStyle(color: Color(0xFF6366F1))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }
}