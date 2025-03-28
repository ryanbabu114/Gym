import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gym/config/config.dart';

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false; // Loading state for API response

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": message});
      _isLoading = true; // Show loading indicator
    });

    try {
      print("Using Gemini API Key: $geminiApiKey"); // Debugging API Key

      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta2/models/gemini-pro:generateContent?key=$geminiApiKey"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message}
              ]
            }
          ],
          "generationConfig": {
            "maxOutputTokens": 150
          }
        }),
      );

      print("API Response Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final botReply = responseData['candidates'][0]['content']['parts'][0]['text'] ?? "No response from AI.";

        setState(() {
          _messages.add({"role": "assistant", "content": botReply});
        });
      } else {
        print("Error Response: ${response.body}");
        setState(() {
          _messages.add({"role": "assistant", "content": "Error: ${response.body}"}); // Show actual error
        });
      }
    } catch (e) {
      print("Exception occurred: $e");
      setState(() {
        _messages.add({"role": "assistant", "content": "Error: Network issue or API failure."});
      });
    } finally {
      setState(() {
        _isLoading = false; // Ensure loading state is cleared
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Chatbot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return Center(child: CircularProgressIndicator()); // Show loading indicator
                }
                final msg = _messages[index];
                return Align(
                  alignment: msg["role"] == "user" ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: msg["role"] == "user" ? Colors.blue[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg["content"]!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Ask something..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
