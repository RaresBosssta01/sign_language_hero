import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../constants.dart'; //Acesta e folderul cu cheia mea secreta de la gemini. Nu o sa incarc cheia pe github, dar AI-ul merge.

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
  

  String _istoricAnterior = ""; 
  

  final _supabase = Supabase.instance.client;
  bool _xpAcordat = false; 

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

      CameraDescription? cameraAleasa;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          cameraAleasa = camera;
          break;
        }
      }
      cameraAleasa ??= cameras.first; 

      _cameraController = CameraController(cameraAleasa, ResolutionPreset.medium);

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Eroare camera: $e");
      if (mounted) {
        setState(() {
          _feedbackCurent = "Eroare la pornirea camerei. Te rugăm să verifici permisiunile.";
        });
      }
    }
  }


  Future<void> _acordaXP() async {
    if (_xpAcordat) return; 
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;


      final response = await _supabase.from('profiluri').select('xp').eq('id', user.id).single();
      int xpCurent = response['xp'] ?? 0;

      await _supabase.from('profiluri').update({'xp': xpCurent + 10}).eq('id', user.id);
      
      _xpAcordat = true;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✨ Genial! Ai primit +10 XP pentru exercițiu!"), 
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Eroare acordare XP: $e");
    }
  }

  Future<void> _analizeazaSemnul({int attempt = 1}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    if (attempt == 1) {
      int countdownValue = 3; 
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
          await _efectueazaAnalizaAI(attempt: 1);
        }
      });
    } else {
      await _efectueazaAnalizaAI(attempt: attempt);
    }
  }

  Future<void> _efectueazaAnalizaAI({required int attempt}) async {
    setState(() {
      _showFlash = true; 
      _feedbackCurent = attempt == 1 
          ? "Analizez poziția... 🤖✨" 
          : "Analizăm mai profund... ⏳ (Încercarea $attempt/3)";
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showFlash = false);
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey); 
      
      final prompt = TextPart("""
        Ești un antrenor de Limbajul Semnelor Românesc (LSR) extrem de prietenos și empatic.
        Utilizatorul exersează semnul: '${widget.numeSemn}'.
        
        ISTORICUL DISCUȚIEI (ce i-ai zis deja): $_istoricAnterior
        
        SARCINA TA:
        1. Amintește-ți cum se execută corect semnul '${widget.numeSemn}' în LSR.
        2. Compară execuția ideală cu ceea ce vezi în imagine (poziția degetelor, orientarea palmei, expresia feței).
        3. Oferă un feedback detaliat și constructiv. Spune-i exact ce face bine și explică-i PAS CU PAS cum să corecteze dacă ceva nu e bine. Dacă poza nu e clară sau nu se vede mâna, roagă-l să încerce din nou.
        4. Păstrează un ton cald, folosește emoji-uri și nu repeta saluturile din istoric.
        5. Răspunde exclusiv în limba română în maxim 3-4 propoziții scurte.
      """);

      final imagePart = DataPart('image/jpeg', imageBytes);
      
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]).timeout(const Duration(seconds: 15)); 

      if (mounted) {
        String noulFeedback = response.text ?? "Oops! Nu am reușit să văd clar. Mai facem o poză? 📸";
        
        setState(() {
          _feedbackCurent = noulFeedback;
          _istoricAnterior = noulFeedback; 
          _isAnalyzing = false;
        });
        

        if (!noulFeedback.contains("Oops") && !noulFeedback.contains("Nu am reușit")) {
           _acordaXP();
        }
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        if (attempt < 3) {

          Future.delayed(const Duration(seconds: 2), () {
            _analizeazaSemnul(attempt: attempt + 1);
          });
        } else {
          setState(() {
            _feedbackCurent = "Conexiunea e prea lentă acum. 😴 Mai încearcă un pic mai târziu!";
            _isAnalyzing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {

        if (e.toString().contains('503') && attempt < 3) {
           Future.delayed(const Duration(seconds: 3), () {
            _analizeazaSemnul(attempt: attempt + 1);
          });
        } else {
          setState(() {
            _feedbackCurent = e.toString().contains('503') 
                ? "Serverele sunt foarte aglomerate în acest moment. 😅 Încearcă peste un minut." 
                : "A apărut o problemă. Ai setat cheia API corect în constants.dart?";
            _isAnalyzing = false;
          });
        }
      }
    }
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
                onPressed: _isAnalyzing ? null : () => _analizeazaSemnul(attempt: 1),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
                child: Text(_isAnalyzing ? "PROCESARE... ✨" : "VERIFICĂ SEMNUL 📸", 
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          Expanded(
            flex: 3, 
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