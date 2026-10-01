import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../data/models/action_item.dart';
import '../data/models/meeting.dart';
import '../data/models/triage_result.dart';

/// Wraps `google_generative_ai`.
/// When [apiKey] is empty the service runs entirely in mock mode — no network
/// call is made and `getMockResult` returns after a simulated 1.5 s delay.
class GeminiService {
  GeminiService({String? apiKey}) : _apiKey = apiKey ?? '' {
    if (_apiKey.isNotEmpty) {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey,
          systemInstruction: Content.system(_kSystemPrompt),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.2,
            maxOutputTokens: 2048,
          ),
        );
      } catch (_) {
        // Silently fall back to mock if the model constructor fails
        // (e.g. wrong package version at compile time).
        _model = null;
      }
    }
  }

  final String _apiKey;
  GenerativeModel? _model;

  bool get isLive => _model != null;

  // ── Public entry point ────────────────────────────────────────────────────

  Future<TriageResult> analyzeMeeting(Meeting meeting, String userNotes) async {
    final content =
        userNotes.trim().isNotEmpty ? userNotes : (meeting.transcript ?? meeting.description);

    if (_model == null || content.trim().isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1500));
      return _mockResult(meeting);
    }

    try {
      final prompt = '''
Meeting Title: ${meeting.title}
Participants: ${meeting.participants.join(', ')}
Duration: ${meeting.durationMinutes} minutes
Date: ${meeting.scheduledAt.toIso8601String()}

Transcript / Notes:
$content
''';
      final response =
          await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      if (text.trim().isEmpty) return _mockResult(meeting);

      final json = jsonDecode(text) as Map<String, dynamic>;
      return TriageResult.fromJson(
        {...json, 'modelUsed': 'gemini-1.5-flash'},
        meeting.id,
      );
    } catch (_) {
      // Network / parse failures silently fall back to mock.
      return _mockResult(meeting);
    }
  }

  // ── Mock fallback ─────────────────────────────────────────────────────────

  TriageResult _mockResult(Meeting meeting) {
    final p = meeting.participants;
    return TriageResult(
      meetingId: meeting.id,
      summary:
          'The team aligned on key priorities and established clear ownership of '
          'deliverables. Stakeholders reached consensus on the primary objectives '
          'and committed to defined timelines with critical action items assigned '
          'to appropriate team members.',
      keyDecisions: [
        'Primary milestone deadline confirmed and locked',
        'Ownership structure established across all functional teams',
        'Weekly communication cadence agreed upon by stakeholders',
        'Risk mitigation strategy reviewed and approved',
      ],
      actionItems: [
        ActionItem(
          meetingId: meeting.id,
          title: 'Prepare and distribute meeting summary to all stakeholders',
          assignedTo: p.isNotEmpty ? p[0] : 'Team Lead',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          priority: ActionPriority.high,
        ),
        ActionItem(
          meetingId: meeting.id,
          title: 'Review and validate updated project scope document',
          assignedTo: p.length > 1 ? p[1] : 'Project Manager',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          priority: ActionPriority.medium,
        ),
        ActionItem(
          meetingId: meeting.id,
          title: 'Schedule follow-up session for open blockers',
          assignedTo: p.isNotEmpty ? p[0] : 'Team Lead',
          dueDate: DateTime.now().add(const Duration(days: 7)),
          priority: ActionPriority.low,
        ),
      ],
      riskFlags: [
        'Timeline dependencies on third-party deliverables not yet confirmed',
        'Resource availability for parallel workstreams needs verification',
      ],
      suggestedFollowUp:
          'Conduct a progress check-in in 5 business days to ensure action items '
          'are on track and surface any emerging blockers before they impact the timeline.',
      sentimentScore: 0.74,
      priorityScore: 78,
      modelUsed: 'mock',
    );
  }

  // ── System prompt ─────────────────────────────────────────────────────────

  static const String _kSystemPrompt = r'''
You are a world-class meeting intelligence assistant.
Analyse the meeting transcript or notes and respond ONLY with a single valid
JSON object matching this exact schema — no markdown, no preamble:

{
  "summary": "string – 2-3 sentence executive summary",
  "keyDecisions": ["string", ...],
  "actionItems": [
    {
      "title": "string",
      "assignedTo": "string",
      "dueDate": "YYYY-MM-DD or null",
      "priority": "low|medium|high",
      "isCompleted": false
    }
  ],
  "riskFlags": ["string", ...],
  "suggestedFollowUp": "string",
  "sentimentScore": 0.0,
  "priorityScore": 0
}
''';
}
