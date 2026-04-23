import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';

// Importăm cheia secretă!
import '../constants.dart'; 

class MirrorScreen extends StatefulWidget {
  final String numeSemn;
  final String sfatAI;

  const MirrorScreen({super.key, required this.numeSemn, required this.sfatAI});

  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  bool _isAnalyzing = false;
  late String _feedbackCurent;
  bool _showFlash = false;
  
  // MEMORIA AI
  String _istoricAnterior = ""; 

  @override
  void initState() {
    super.initState();
    _feedbackCurent = widget.sfatAI;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final primaCamera = cameras.first;
      _cameraController = CameraController(primaCamera, ResolutionPreset.medium);

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Eroare camera: $e");
    }
  }

  Future<void> _analizeazaSemnul() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    int countdownValue = 5;
    setState(() {
      _isAnalyzing = true;
      _feedbackCurent = "Pregătește-te în $countdownValue... ✨";
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      countdownValue--;
      if (countdownValue > 0) {
        setState(() => _feedbackCurent = "Pregătește-te în $countdownValue... ✨");
      } else {
        timer.cancel();
        
        setState(() {
          _showFlash = true; 
          _feedbackCurent = "Analizez poziția... 🤖✨";
        });

        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showFlash = false);
        });

        try {
          final image = await _cameraController!.takePicture();
          final imageBytes = await image.readAsBytes();

          // Aici folosim cheia din constants.dart
          final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
          
          // PROMPT NOU: Mai detaliat și ancorat în semnul specific
          final prompt = TextPart("""
            Ești un antrenor de Limbajul Semnelor Românesc (LSR) extrem de prietenos și empatic.
            Utilizatorul exersează semnul: '${widget.numeSemn}'.
            
            ISTORICUL DISCUȚIEI (ce i-ai zis deja): $_istoricAnterior
            
            SARCINA TA:
            1. Amintește-ți cum se execută corect semnul '${widget.numeSemn}' în LSR.
            2. Compară execuția ideală cu ceea ce vezi în imagine (poziția degetelor, orientarea palmei, expresia feței, mâna dominantă).
            3. Oferă un feedback detaliat și constructiv. Spune-i exact ce face bine și explică-i PAS CU PAS cum să corecteze dacă ceva nu e bine (ex: 'Îndreaptă mai mult degetul arătător' sau 'Ține palma orientată spre tine').
            4. Păstrează un ton cald, folosește emoji-uri (👍, ✨, 🙌) și nu repeta saluturile din istoric.
            5. Răspunde exclusiv în limba română.
          """);

          final imagePart = DataPart('image/jpeg', imageBytes);
          
          final response = await model.generateContent([
            Content.multi([prompt, imagePart])
          ]).timeout(const Duration(seconds: 20));

          if (mounted) {
            setState(() {
              String noulFeedback = response.text ?? "Oops! Nu mi-am dat seama. Mai facem o poză? 📸";
              _feedbackCurent = noulFeedback;
              _istoricAnterior = noulFeedback; 
            });
          }
        } on TimeoutException catch (_) {
          if (mounted) {
            setState(() {
              _feedbackCurent = "Conexiunea merge cam greu. 😴 Mai încearcă o dată!";
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _feedbackCurent = e.toString().contains('503') 
                  ? "Suntem cam aglomerați pe server! 😅 Dă-mi 10 secunde de pauză." 
                  : "Eroare: Verifică dacă ai pus cheia corectă în constants.dart!";
            });
          }
        } finally {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.numeSemn, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _isAnalyzing ? Colors.amber : Colors.tealAccent, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _isCameraInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_cameraController!),
                              if (_showFlash) Container(color: Colors.white), 
                            ],
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analizeazaSemnul,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
                child: Text(_isAnalyzing ? "PROCESARE... ✨" : "VERIFICĂ SEMNUL 📸", 
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          Expanded(
            flex: 3, // Am mărit puțin zona de text pentru feedback-ul detaliat
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: _isAnalyzing ? Colors.amber : Colors.tealAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text("ANALIZA DETALIATĂ AI", 
                            style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_feedbackCurent, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}