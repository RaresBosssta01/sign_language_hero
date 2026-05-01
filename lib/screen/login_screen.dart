import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin_portal_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false; 

  late AnimationController _handsAnimController;
  late AnimationController _logoAnimController;

  @override
  void initState() {
    super.initState();
    _handsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _handsAnimController.dispose();
    _logoAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loginBackend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;
      if (user == null) throw Exception("Nu am putut prelua datele utilizatorului.");

      final profil = await supabase
          .from('profiluri')
          .select('rol, status, prenume') 
          .eq('id', user.id)
          .maybeSingle();

      if (profil == null) throw Exception("Profilul nu există în baza de date!");

      String rol = profil['rol'];
      String status = profil['status'];
      String numeUtilizator = profil['prenume'] ?? "Erou";

      if (!mounted) return;

      if (rol == 'admin') {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPortalScreen()));
        
      } else if (rol == 'voluntar') {
        if (status == 'pending') {
          await supabase.auth.signOut();
          setState(() => _isLoading = false);
          _showStatusDialog("Cont în așteptare ⏳", "Contul tău de voluntar este încă în curs de verificare de către un administrator.");
          return;
        } else if (status == 'respins') {
          await supabase.auth.signOut();
          setState(() => _isLoading = false);
          _showStatusDialog("Cerere respinsă 🚫", "Ne pare rău, dar cererea ta a fost respinsă de echipa administrativă.");
          return;
        } else if (status == 'blocat') {
          await supabase.auth.signOut();
          setState(() => _isLoading = false);
          _showStatusDialog("Cont blocat 🛑", "Acest cont a fost restricționat pentru încălcarea regulilor platformei.");
          return;
        } else if (status == 'aprobat') {
          setState(() => _isLoading = false);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(numeUtilizator: numeUtilizator, rol: rol)));
        }
      } else {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(numeUtilizator: numeUtilizator, rol: rol)));
      }

    } on AuthException catch (_) {
      setState(() => _isLoading = false);
      _showError("Email sau parolă incorecte!");
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Eroare de sistem: $e");
    }
  }

  void _showStatusDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("AM ÎNȚELES", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0083B0))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)], 
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildAnimatedHand('👋', const Alignment(-0.8, -0.7), 0.0, -0.2), 
              _buildAnimatedHand('🤟', const Alignment(0.8, -0.6), 0.4, 0.2),  
              _buildAnimatedHand('✋', const Alignment(-0.85, 0.7), 0.7, -0.1), 
              _buildAnimatedHand('👏', const Alignment(0.85, 0.6), 0.2, 0.15),  

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450), 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        _buildAnimatedLogo(),
                        const SizedBox(height: 35),
                        
                        Container(
                          padding: const EdgeInsets.all(35),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF0083B0).withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 15))
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                const Center(
                                  child: Text("Bine ai revenit!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                                ),
                                const SizedBox(height: 8),
                                const Center(
                                  child: Text("Comunitatea te așteaptă", style: TextStyle(fontSize: 15, color: Colors.grey)),
                                ),
                                const SizedBox(height: 40),
                                
                                const Text("  Adresă de email", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF00B4DB)),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00B4DB), width: 2)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Te rog introdu un email.';
                                    if (!value.contains('@')) return 'Te rog introdu un email valid.';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 25),
                                
                                const Text("  Parolă", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00B4DB)),
                                    suffixIcon: IconButton(
                                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                      onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00B4DB), width: 2)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Te rog introdu parola.';
                                    return null;
                                  },
                                ),
                                
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                                    }, 
                                    child: const Text("Ai uitat parola?", style: TextStyle(color: Color(0xFF0083B0), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [BoxShadow(color: const Color(0xFF0083B0).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _loginBackend,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ),
                                      child: _isLoading 
                                        ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Text("Intră în cont →", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 35),
                        
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Nu ai un cont încă? ",
                              style: TextStyle(color: Colors.black54, fontSize: 15),
                              children: [
                                TextSpan(text: "Înregistrează-te", style: TextStyle(color: Color(0xFF0083B0), fontWeight: FontWeight.bold))
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoAnimController,
      builder: (context, child) {
        final scale = 1.0 + (_logoAnimController.value * 0.05);
        final glowBlur = 10.0 + (_logoAnimController.value * 20.0);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B4DB).withValues(alpha: 0.6), 
                  blurRadius: glowBlur, 
                  offset: const Offset(0, 8)
                )
              ],
            ),
            child: const Icon(Icons.sign_language, color: Colors.white, size: 55),
          ),
        );
      }
    );
  }

  Widget _buildAnimatedHand(String emoji, Alignment alignment, double delayOffset, double baseRotation) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: _handsAnimController,
        builder: (context, child) {
          final double wave = math.sin((_handsAnimController.value * 2 * math.pi) + (delayOffset * math.pi * 2));
          
          return Transform.translate(
            offset: Offset(0, wave * 25), 
            child: Transform.rotate(
              angle: baseRotation + (wave * 0.15), 
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 85, 
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 15))],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}