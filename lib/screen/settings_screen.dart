import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Variabile pentru a tine minte starea butoanelor (ON/OFF)
  bool _vibrationAlerts = true;
  bool _highContrast = false;
  bool _shareLocation = true;
  bool _ghostMode = false; // Modul "Nu ma deranja" pentru voluntari
  
  String _preferredInterpreter = "Oricare"; // Ideea ta geniala!

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text("Setări & Preferințe", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          
          // --- SECTIUNEA 1: Accesibilitate (Esential pentru deficiente de auz) ---
          const Text("ACCESIBILITATE", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                "Alerte prin Vibrație Intensă", 
                "Telefonul va vibra puternic la urgențe", 
                Icons.vibration_rounded, 
                Colors.orange, 
                _vibrationAlerts, 
                (val) => setState(() => _vibrationAlerts = val)
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Mod Contrast Ridicat", 
                "Pentru vizibilitate mai bună", 
                Icons.contrast_rounded, 
                Colors.purple, 
                _highContrast, 
                (val) => setState(() => _highContrast = val)
              ),
            ]
          ),
          const SizedBox(height: 25),

          // --- SECTIUNEA 2: Siguranta si Confort (Ideea ta!) ---
          const Text("SIGURANȚĂ & CONFORT", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _buildSettingsCard(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.pink.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.people_alt_rounded, color: Colors.pink),
                ),
                title: const Text("Preferință Interpret", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Selectează genul interpretului (pentru confortul tău)"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                  child: Text(_preferredInterpreter, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                ),
                onTap: () {
                  _showInterpreterPreferenceDialog();
                },
              ),
              _buildDivider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.contact_emergency_rounded, color: Colors.red),
                ),
                title: const Text("Contacte de Urgență (ICE)", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Persoane notificate automat la un SOS"),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () {},
              ),
            ]
          ),
          const SizedBox(height: 25),

          // --- SECTIUNEA 3: Locatie si Intimitate ---
          const Text("LOCAȚIE & INTIMITATE", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                "Partajează Locația Live", 
                "Necesar pentru a fi găsit pe hartă", 
                Icons.location_on_rounded, 
                Colors.blue, 
                _shareLocation, 
                (val) => setState(() => _shareLocation = val)
              ),
              _buildDivider(),
              _buildSwitchTile(
                "Mod Invizibil (Off-Duty)", 
                "Nu vei mai primi cereri de urgență (Ideal pentru voluntari la muncă)", 
                Icons.visibility_off_rounded, 
                Colors.blueGrey, 
                _ghostMode, 
                (val) => setState(() => _ghostMode = val)
              ),
            ]
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: Cardul alb care tine setarile ---
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  // --- WIDGET HELPER: Butonul de tip ON/OFF (Switch) ---
  Widget _buildSwitchTile(String title, String subtitle, IconData icon, Color iconColor, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1E88E5),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }

  // --- WIDGET HELPER: Linia de separare intre setari ---
  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.shade200);
  }

  // --- FUNCTIE: Fereastra (Dialog) pentru alegerea genului ---
  void _showInterpreterPreferenceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Confortul tău e prioritar", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("În caz de urgență, preferi să fii conectat cu:"),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDialogButton("O Femeie 👩", "Femeie"),
                const SizedBox(height: 10),
                _buildDialogButton("Un Bărbat 👨", "Barbat"),
                const SizedBox(height: 10),
                _buildDialogButton("Nu am o preferință", "Oricare"),
              ],
            )
          ],
        );
      }
    );
  }

  Widget _buildDialogButton(String label, String value) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _preferredInterpreter == value ? const Color(0xFF1E88E5) : Colors.grey.shade100,
        foregroundColor: _preferredInterpreter == value ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(vertical: 12)
      ),
      onPressed: () {
        setState(() {
          _preferredInterpreter = value;
        });
        Navigator.pop(context); // Inchide fereastra
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}