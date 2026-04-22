import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/chat_message.dart';
import '../../global/global_api.dart';
import '../../core/services/auth_storage_service.dart';

class AiChatProvider extends ChangeNotifier {
  bool _isOpen = false;
  bool _isLoading = false;
  
  List<ChatMessage> _messages = [
    ChatMessage(
      role: 'ai',
      content: 'Hi! I am your HIMS Agent. Ask me questions about patient data or revenue, like "Which service made the most revenue in July 2025?"',
    )
  ];

  bool get isOpen => _isOpen;
  bool get isLoading => _isLoading;
  List<ChatMessage> get messages => _messages;

  void toggleChat() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void openChat() {
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  void closeChat() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages = [
      ChatMessage(
        role: 'ai',
        content: 'Chat history cleared. How can I help you today?',
      )
    ];
    notifyListeners();
  }

  Future<void> sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(role: 'user', content: query));
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get Token for Authorization
      final storage = AuthStorageService();
      final token = await storage.getToken();

      // 2. Prepare History (last 4 messages for context)
      final history = _messages
          .where((m) => m != _messages.last) // exclude the one we just added
          .toList()
          .reversed
          .take(4)
          .toList()
          .reversed
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/ai/query-data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'query': query,
          'history': history,
        }),
      );

      print('AI API Response Status: ${response.statusCode}');
      print('AI API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Match React backend structure: { success: true, answer: "...", extractedEntities: {...} }
        if (data['success'] == true) {
          _messages.add(ChatMessage(
            role: 'ai',
            content: (data['answer'] ?? data['message'] ?? '...').toString(),
            entities: data['extractedEntities'] as Map<String, dynamic>?,
          ));
        } else {
          _messages.add(ChatMessage(
            role: 'ai',
            content: (data['message'] ?? 'The AI agent encountered an issue.').toString(),
          ));
        }
      } else {
        _messages.add(ChatMessage(
          role: 'ai',
          content: 'Server error: ${response.statusCode}. Please try again later.',
        ));
      }
    } catch (error) {
      print('Error calling AI API: $error');
      _messages.add(ChatMessage(
        role: 'ai',
        content: "Sorry, I couldn't process your request at this time. Please check your internet connection.",
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
