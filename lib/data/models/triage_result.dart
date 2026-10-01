import 'package:uuid/uuid.dart';
import 'action_item.dart';

/// The structured output returned by `GeminiService.analyzeMeeting`.
/// Immutable except for the `actionItems` list whose elements are mutable
/// (see `ActionItem.isCompleted`).
class TriageResult {
  TriageResult({
    String? id,
    required this.meetingId,
    required this.summary,
    required this.keyDecisions,
    required this.actionItems,
    required this.riskFlags,
    required this.suggestedFollowUp,
    required this.sentimentScore,
    required this.priorityScore,
    DateTime? generatedAt,
    this.modelUsed = 'mock',
  })  : id = id ?? const Uuid().v4(),
        generatedAt = generatedAt ?? DateTime.now();

  final String id;
  final String meetingId;
  final String summary;
  final List<String> keyDecisions;

  /// Mutable list so `ActionItem.isCompleted` toggles propagate without
  /// rebuilding the entire `Meeting` object graph.
  final List<ActionItem> actionItems;
  final List<String> riskFlags;
  final String suggestedFollowUp;

  /// 0.0 (negative) → 1.0 (very positive)
  final double sentimentScore;

  /// 0–100 priority urgency score
  final int priorityScore;
  final DateTime generatedAt;

  /// 'mock' | 'gemini-1.5-flash'
  final String modelUsed;

  factory TriageResult.fromJson(Map<String, dynamic> json, String meetingId) {
    return TriageResult(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      meetingId: meetingId,
      summary: (json['summary'] as String?) ?? '',
      keyDecisions: ((json['keyDecisions'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      actionItems: ((json['actionItems'] as List?) ?? [])
          .map((e) =>
              ActionItem.fromJson(e as Map<String, dynamic>, meetingId))
          .toList(),
      riskFlags: ((json['riskFlags'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      suggestedFollowUp: (json['suggestedFollowUp'] as String?) ?? '',
      sentimentScore:
          (json['sentimentScore'] as num?)?.toDouble() ?? 0.5,
      priorityScore: (json['priorityScore'] as num?)?.toInt() ?? 50,
      generatedAt: json['generatedAt'] != null
          ? (DateTime.tryParse(json['generatedAt'] as String) ??
              DateTime.now())
          : DateTime.now(),
      modelUsed: (json['modelUsed'] as String?) ?? 'mock',
    );
  }
}
