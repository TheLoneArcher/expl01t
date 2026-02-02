import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:provider/provider.dart';
import 'package:camp_x/utils/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  // Variables
  final List<Content> _history = [];
  bool _isLoading = false;     // Loading indicator
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  GenerativeModel? _model;
  
  // To show in UI
  final List<Map<String, String>> _displayMessages = [];

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    // secure API key loading from .env at runtime
    final envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    // Also check String.fromEnvironment as backup for CI/CD/Release builds using dart-define
    final fallbackKey = const String.fromEnvironment('GEMINI_API_KEY');
    final apiKey = envKey.isNotEmpty ? envKey : fallbackKey;

    if (apiKey.isNotEmpty) {
      setState(() {
        _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      });
    }
  }

  // Async fetch context
  Future<String> _buildStudentContext(Map<String, dynamic> user) async {
    try {
      final uid = user['uid'];
      final marksSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('marks').get();
      final attSnap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('attendance').limit(10).get(); // Last 10 days
      
      StringBuffer contextBuffer = StringBuffer();
      contextBuffer.writeln("You are CampX AI, a helpful assistant for a student named ${user['name']}.");
      contextBuffer.writeln("Class: ${user['classId']}. Role: ${user['role']}.");
      
      if (marksSnap.docs.isNotEmpty) {
        contextBuffer.writeln("Recent Exam Marks:");
        for (var doc in marksSnap.docs) {
          contextBuffer.writeln("- Exam ${doc.id}: ${doc.data()}");
        }
      }

      if (attSnap.docs.isNotEmpty) {
        contextBuffer.writeln("Recent Attendance (Last 10 records):");
        for (var doc in attSnap.docs) {
          contextBuffer.writeln("- Date ${doc.id}: ${doc.data()}");
        }
      }
      
      return contextBuffer.toString();
    } catch (e) {
      return "Context fetch failed. Proceeding with general assistance."; 
    }
  }

  Future<void> _sendMessage() async {
    if (_model == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    setState(() {
      _displayMessages.add({'role': 'user', 'text': text});
      _isLoading = true;
      _controller.clear();
    });
    
    _scrollToBottom();

    try {
      final chat = _model!.startChat(history: _history);
      
      // Inject context if it's the first message or history is short
      String messageToSend = text;
      if (_history.isEmpty && user != null) {
         final contextStr = await _buildStudentContext(user);
         messageToSend = "System Context: $contextStr\n\nUser Question: $text";
      }

      final content = Content.text(messageToSend);
      final response = await chat.sendMessage(content);
      
      final responseText = response.text ?? "I'm sorry, I didn't get that.";

      setState(() {
        _history.add(content);
        if (response.text != null) {
           _history.add(Content.model([TextPart(response.text!)]));
        }
        _displayMessages.add({'role': 'model', 'text': responseText});
        _isLoading = false;
      });
      _scrollToBottom();
      
    } catch (e) {
      setState(() {
        _displayMessages.add({'role': 'model', 'text': "Error: $e"});
        _isLoading = false;
      });
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Dispose controllers
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _model == null 
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key_outlined, size: 64, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 24),
                  Text(
                    "Gemini API Key Required",
                    style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "The API key was not found in the environment.\nPlease enter it manually to continue.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Enter API Key",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.key),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        final key = value.trim();
                        debugPrint("Manual Key Entered: ${key.substring(0, 4)}..."); // Debug log
                        setState(() {
                          _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: key);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          )
        : Column(
        children: [
          Expanded(
            child: _displayMessages.isEmpty 
             ? Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.auto_awesome, size: 60, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                     const SizedBox(height: 16),
                     const Text("Ask me anything about your academics!"),
                   ],
                 )
               )
             : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _displayMessages.length,
              itemBuilder: (context, index) {
                final msg = _displayMessages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2) 
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(msg['text']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      hintText: "Type a message...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
