import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _postController = TextEditingController();

  // 1. MEMORIA FORUMULUI (Aici salvam postarile ca sa le putem modifica)
  final List<Map<String, dynamic>> _forumPosts = [
    {
      "name": "Mihai Popescu", "role": "Utilizator", "color": Colors.orange, "time": "Acum 2 ore",
      "content": "Salut! Are cineva experiență cu programările la Primăria Sectorului 3? Am nevoie de un interpret pentru depunerea unor acte vineri.",
      "likes": 12, "comments": 4, "isOfficial": false
    },
    {
      "name": "Andrei (Voluntar)", "role": "Interpret Fluent", "color": Colors.green, "time": "Acum 5 ore",
      "content": "Sfatul Zilei 💡: Nu uitați că puteți folosi dicționarul LSR din aplicație chiar și când sunteți offline!",
      "likes": 45, "comments": 8, "isOfficial": true
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Ascultam cand utilizatorul schimba tab-ul ca sa schimbam butonul plutitor
    _tabController.addListener(() { setState(() {}); });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text("Comunitate & Mesaje", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E88E5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E88E5),
          indicatorWeight: 3,
          tabs: const [Tab(text: "🗣️ Forum Public"), Tab(text: "💬 Mesaje Private")],
        ),
      ),
      
      body: TabBarView(
        controller: _tabController,
        children: [_buildForumTab(), _buildMessagesTab()],
      ),

      // BUTONUL PLUTITOR DINAMIC
      floatingActionButton: _tabController.index == 0 
        ? FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1E88E5),
            icon: const Icon(Icons.create_rounded, color: Colors.white),
            label: const Text("Postare Nouă", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _showCreatePostModal(), // Deschide fereastra de scris
          )
        : null, // Pe tab-ul de mesaje il ascundem, pentru ca intram in chat direct
    );
  }

  // ==========================================
  // TAB 1: FORUM (Dinamic)
  // ==========================================
  Widget _buildForumTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 80),
      physics: const BouncingScrollPhysics(),
      itemCount: _forumPosts.length,
      itemBuilder: (context, index) {
        final post = _forumPosts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildPostCard(
            authorName: post["name"], authorRole: post["role"], avatarColor: post["color"],
            timeAgo: post["time"], content: post["content"], likes: post["likes"],
            comments: post["comments"], isOfficial: post["isOfficial"],
          ),
        );
      },
    );
  }

  // FUNCȚIA CARE DESCHIDE TASTATURA PENTRU POSTARE NOUĂ
  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite ridicarea peste tastatura
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          // Padding magic care impinge fereastra deasupra tastaturii
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Scrie o postare nouă", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _postController,
                maxLines: 4,
                autofocus: true, // Deschide tastatura automat
                decoration: InputDecoration(
                  hintText: "Ai o întrebare sau un sfat pentru comunitate?",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    if (_postController.text.isNotEmpty) {
                      // 2. SALVĂM POSTAREA NOUĂ ÎN MEMORIE
                      setState(() {
                        _forumPosts.insert(0, { // O punem pe pozitia 0 (sus de tot)
                          "name": "Rareș (Erou)", "role": "Nivel 3", "color": Colors.blue, "time": "Chiar acum",
                          "content": _postController.text, "likes": 0, "comments": 0, "isOfficial": false
                        });
                      });
                      _postController.clear(); // Curatam textul
                      Navigator.pop(context); // Inchidem tastatura si fereastra
                    }
                  },
                  child: const Text("Publică în Comunitate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: MESAJE
  // ==========================================
  Widget _buildMessagesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      physics: const BouncingScrollPhysics(),
      children: [
        // Cand dam click pe Andrei, ne duce pe Ecranul de Chat Real!
        _buildChatTile("Andrei (Voluntar)", "Sunt pe drum, ajung în 5 minute!", "10:42", true, 2, context),
        Divider(height: 1, indent: 80, endIndent: 20, color: Colors.grey.shade200),
        _buildChatTile("Maria I.", "Gata, am rezolvat cu programarea.", "Ieri", false, 0, context),
      ],
    );
  }

  Widget _buildPostCard({required String authorName, required String authorRole, required Color avatarColor, required String timeAgo, required String content, required int likes, required int comments, bool isOfficial = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isOfficial ? Colors.green.withValues(alpha: 0.3) : Colors.transparent, width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: avatarColor.withValues(alpha: 0.2), child: Text(authorName[0], style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold))),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(authorRole, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
              Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 20, color: Colors.blue), const SizedBox(width: 5), Text("$likes", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.grey), const SizedBox(width: 5), Text("$comments", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatTile(String name, String lastMessage, String time, bool isOnline, int unreadCount, BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.blue.shade50, child: Text(name[0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20))),
          if (isOnline) Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))
        ],
      ),
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(time, style: TextStyle(fontSize: 12, color: unreadCount > 0 ? Colors.green : Colors.grey, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal))]),
      subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
      trailing: unreadCount > 0 ? Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: Text("$unreadCount", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))) : null,
      onTap: () {
        // LA CLICK: DESCHIDEM ECRANUL DE CHAT INTERACTIV
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatName: name)));
      },
    );
  }
}

// =====================================================================
// NOUA PAGINA: ECRANUL DE CHAT INDIVIDUAL (Ca pe WhatsApp)
// =====================================================================
class ChatScreen extends StatefulWidget {
  final String chatName;
  const ChatScreen({super.key, required this.chatName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  // Memoria scurta a acestui chat
  final List<Map<String, dynamic>> _messages = [
    {"text": "Salut! Ai dat pe butonul de urgență. Cu ce te pot ajuta?", "isMe": false},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        // Adaugam mesajul nostru
        _messages.add({"text": _messageController.text, "isMe": true});
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: Colors.blue.shade50, child: Text(widget.chatName[0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            Text(widget.chatName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_rounded, color: Color(0xFF1E88E5)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.phone_rounded, color: Color(0xFF1E88E5)), onPressed: () {}),
        ],
      ),
      
      body: Column(
        children: [
          // 1. ZONA CU MESAJE
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isMe = msg["isMe"];
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF1E88E5) : Colors.white,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                        bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. BARA DE SCRIS DE JOS (Tastatura)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.grey, size: 28), onPressed: () {}),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Scrie un mesaj...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                      // Permitem trimiterea cand apesi Enter pe tastatura
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage, // Trimitere la click pe sageata
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
}