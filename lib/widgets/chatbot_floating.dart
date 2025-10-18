import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:proyecto_flutter_ia/services/geminis_service.dart';

class ChatbotFloating extends StatefulWidget {
  const ChatbotFloating({super.key});

  @override
  State<ChatbotFloating> createState() => _ChatbotFloatingState();
}

class _ChatbotFloatingState extends State<ChatbotFloating> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = true;
  String? _error;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
      _controller.clear();
    });

    try {
      // 🧠 Instrucción mejorada para formato y nivel medio de detalle
      final fullPrompt = """
Eres un asistente llamado *EmotiCare*, claro, amable y organizado.
Responde en un formato **Markdown** bien estructurado:
- Usa **negritas** para conceptos importantes.
- Usa viñetas o listas si corresponde.
- Explica con detalle medio (ni demasiado corto ni muy largo).
- Sé claro, profesional y agradable.

Usuario: $text
""";

      final reply = await GeminiService.sendMessage(fullPrompt);

      setState(() {
        _messages.add({"role": "bot", "text": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "⚠️ Ocurrió un error al procesar tu mensaje.",
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder:
              (_, scrollController) => Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text(
                      "🤖 Asistente EmotiCare",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg["role"] == "user";

                          return Align(
                            alignment:
                                isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isUser
                                        ? const Color(0xFF3B82F6)
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              // 🧩 Usa MarkdownBody para formato enriquecido
                              child: MarkdownBody(
                                data: msg["text"]!,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    color:
                                        isUser ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                  strong: TextStyle(
                                    color: isUser ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  listBullet: TextStyle(
                                    color: isUser ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Escribe tu pregunta...",
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF3B82F6),
                          ),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed:
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_error!))),
        child: const Icon(Icons.error_outline, color: Colors.white),
      );
    }

    return FloatingActionButton(
      onPressed: _openChat,
      backgroundColor: const Color(0xFF3B82F6),
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
    );
  }
}
