import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class Message {
  final String role; // 'user', 'model', 'system'
  final String text;
  final DateTime time;

  Message({required this.role, required this.text, required this.time});
}

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;

  // Replace with your actual Gemini API key
  static const String _apiKey = "AIzaSyBdqrhJ5ZgkXkEiCm7JDiqQgG69giynG-A";

  late GenerativeModel _model;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (_apiKey.isEmpty || _apiKey.startsWith("REPLACE")) {
      setState(() {
        _messages.add(Message(
          role: 'system',
          text:
              '⚠️ Gemini API Key not set. Please configure your API key to enable AI features.',
          time: DateTime.now(),
        ));
      });
      return;
    }

    try {
      // Use a known valid Gemini model
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', // stable model
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.system(
          'You are CampX AI, a helpful campus assistant. Keep responses concise and professional.',
        ),
      );

      _chatSession = await _model.startChat();

      setState(() {
        _messages.add(Message(
          role: 'model',
          text:
              'System Online. Hello! I am CampX AI. How can I assist your academic journey today?',
          time: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(
          role: 'system',
          text: 'Error initializing chat: ${e.toString()}',
          time: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _chatSession == null) return;

    setState(() {
      _messages.add(Message(role: 'user', text: text, time: DateTime.now()));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      setState(() {
        _messages.add(Message(
          role: 'model',
          text: response.text ?? "I'm sorry, I couldn't process that.",
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(
          role: 'model',
          text: 'System Error: ${e.toString()}',
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.5),
            border: Border(bottom: BorderSide(color: theme.primaryColor.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.psychology, color: theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CAMPX INTELLIGENCE",
                    style: GoogleFonts.orbitron(
                        fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text("SYSTEM ACTIVE v1.1",
                          style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.greenAccent)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg.role == 'user';
              final isSystem = msg.role == 'system';

              if (isSystem) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Text(msg.text, style: const TextStyle(color: Colors.amber, fontSize: 13)),
                );
              }

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  constraints:
                      BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? theme.primaryColor : theme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                    border: isUser ? null : Border.all(color: theme.primaryColor.withOpacity(0.2)),
                    boxShadow: [
                      if (isUser)
                        BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.text,
                          style: TextStyle(
                              color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color)),
                      const SizedBox(height: 4),
                      Text(DateFormat('HH:mm').format(msg.time),
                          style: TextStyle(
                              fontSize: 10, color: isUser ? Colors.white70 : Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
          ),

        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.5),
            border: Border(top: BorderSide(color: theme.primaryColor.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: "Type your query...",
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: theme.scaffoldBackgroundColor,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: theme.primaryColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
