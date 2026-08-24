import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'auth_service.dart';

class AIChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Production AI Assistant powered by Google Gemini API.
///
/// Requires GEMINI_API_KEY to be set either:
///   - As a compile-time constant: --dart-define=GEMINI_API_KEY=your_key
///   - Or stored in Firestore at /config/gemini (field: apiKey)
///
/// Falls back to a "credentials required" message if no key is configured.
class AIAssistantService {
  AIAssistantService._internal();
  static final AIAssistantService instance = AIAssistantService._internal();

  final List<AIChatMessage> _history = [];
  final StreamController<List<AIChatMessage>> _controller =
      StreamController<List<AIChatMessage>>.broadcast();

  Stream<List<AIChatMessage>> get chatStream => _controller.stream;

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _initialized = false;

  static const String _systemPrompt = '''
You are iLiving Luxury Concierge, the AI assistant for iLiving — a premium real estate platform in Egypt.

Your capabilities:
- Answer questions about property compounds, units, pricing, and availability
- Explain payment schedules, installment plans, and wallet balances
- Guide users through gate access QR code generation
- Help with maintenance ticket submission
- Provide information about the Prypco fractional ownership platform
- Explain contract signing and document verification processes
- Assist with electricity bill payments and utility management

Guidelines:
- Be professional, concise, and helpful
- Use the client's name when available
- Respond in the same language the user writes in (Arabic or English)
- If asked about specific account data you don't have, direct the user to the relevant app section
- Never fabricate specific numbers (balances, prices) — direct users to check the app
- Always maintain a luxury concierge tone
''';

  /// Initializes the Gemini model and chat session.
  Future<void> _ensureInitialized() async {
    if (_initialized && _model != null) return;

    String apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

    // If no compile-time key, try fetching from Firestore config
    if (apiKey.isEmpty) {
      try {
        final configDoc = await FirebaseFirestore.instance
            .collection('config')
            .doc('gemini')
            .get();
        if (configDoc.exists) {
          apiKey = configDoc.data()?['apiKey'] as String? ?? '';
        }
      } catch (e) {
        debugPrint('[AIAssistant] Failed to fetch Gemini API key from Firestore: $e');
      }
    }

    if (apiKey.isEmpty) {
      debugPrint('[AIAssistant] No Gemini API key configured. AI responses will be unavailable.');
      _initialized = true; // Mark as initialized to avoid repeated attempts
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
        topP: 0.95,
      ),
    );

    _chatSession = _model!.startChat();
    _initialized = true;
    debugPrint('[AIAssistant] Gemini model initialized successfully');
  }

  /// Resets and initializes the AI chat session.
  void initSession() {
    _history.clear();
    _chatSession = _model?.startChat();

    final profile = AuthService.instance.currentProfile;
    final welcome = profile != null
        ? "Hello ${profile.displayName}, welcome to your iLiving Luxury Concierge. How may I assist you with your properties today?"
        : "Welcome to your iLiving Luxury Concierge. How may I assist you today?";
    _history.add(AIChatMessage(text: welcome, isUser: false, timestamp: DateTime.now()));
    _controller.add(List.from(_history));
  }

  /// Sends a message to the Gemini AI and streams back the response.
  Future<void> askAssistant(String question) async {
    if (question.trim().isEmpty) return;

    _history.add(AIChatMessage(text: question, isUser: true, timestamp: DateTime.now()));
    _controller.add(List.from(_history));

    await _ensureInitialized();

    if (_model == null || _chatSession == null) {
      // No API key configured — return a clear error message
      _history.add(AIChatMessage(
        text: 'AI Assistant requires a Gemini API key. '
            'Please configure it via --dart-define=GEMINI_API_KEY=your_key '
            'or add it to Firestore at /config/gemini (field: apiKey).',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _controller.add(List.from(_history));
      return;
    }

    try {
      // Add user context to the message
      final profile = AuthService.instance.currentProfile;
      final contextPrefix = profile != null
          ? '[Context: User is ${profile.displayName}, client ID: ${profile.clientId}]\n'
          : '';

      final response = await _chatSession!.sendMessage(
        Content.text('$contextPrefix$question'),
      );

      final responseText = response.text ?? 'I apologize, I could not process that request. Please try again.';

      _history.add(AIChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _controller.add(List.from(_history));

      // Persist the conversation to Firestore for analytics
      _persistConversation(question, responseText);
    } catch (e) {
      debugPrint('[AIAssistant] Gemini API error: $e');

      String errorMessage;
      if (e.toString().contains('API_KEY_INVALID') || e.toString().contains('403')) {
        errorMessage = 'The Gemini API key is invalid or has been revoked. Please update your credentials.';
      } else if (e.toString().contains('RESOURCE_EXHAUSTED') || e.toString().contains('429')) {
        errorMessage = 'The AI service is experiencing high demand. Please try again in a moment.';
      } else {
        errorMessage = 'I encountered an error processing your request. Please try again.';
      }

      _history.add(AIChatMessage(
        text: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _controller.add(List.from(_history));
    }
  }

  /// Persists AI conversations to Firestore for analytics and audit.
  Future<void> _persistConversation(String question, String answer) async {
    try {
      final user = AuthService.instance.currentProfile;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('ai_conversations')
          .add({
        'clientId': user.clientId,
        'question': question,
        'answer': answer,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[AIAssistant] Failed to persist conversation: $e');
    }
  }
}
