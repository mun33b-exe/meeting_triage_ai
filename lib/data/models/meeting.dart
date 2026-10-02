import 'package:uuid/uuid.dart';
import 'triage_result.dart';

enum MeetingStatus {
  needsTriage,
  inProgress,
  synced,
  scheduled,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case MeetingStatus.needsTriage:
        return 'NEEDS TRIAGE';
      case MeetingStatus.inProgress:
        return 'IN PROGRESS';
      case MeetingStatus.synced:
        return 'SYNCED';
      case MeetingStatus.scheduled:
        return 'SCHEDULED';
      case MeetingStatus.completed:
        return 'COMPLETED';
      case MeetingStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

enum MeetingPriority {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case MeetingPriority.low:
        return 'LOW';
      case MeetingPriority.medium:
        return 'MEDIUM';
      case MeetingPriority.high:
        return 'HIGH';
      case MeetingPriority.critical:
        return 'CRITICAL';
    }
  }
}

/// Root aggregate — fully immutable. Use `copyWith` to produce new instances
/// with changed fields; the provider holds the canonical list.
class Meeting {
  Meeting({
    String? id,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.participants,
    this.transcript,
    this.status = MeetingStatus.scheduled,
    this.priority = MeetingPriority.medium,
    this.tags = const [],
    DateTime? createdAt,
    this.triageResult,
    this.relativeTime,
    this.audioDuration,
    this.progressText,
    this.progressPercent,
    this.syncStatusText,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final int durationMinutes;
  final List<String> participants;

  /// Raw meeting transcript or free-form notes supplied by the user.
  final String? transcript;
  final MeetingStatus status;
  final MeetingPriority priority;
  final List<String> tags;
  final DateTime createdAt;

  /// Null until the first AI triage pass completes.
  final TriageResult? triageResult;

  final String? relativeTime;
  final String? audioDuration;
  final String? progressText;
  final double? progressPercent;
  final String? syncStatusText;

  // ── copyWith ──────────────────────────────────────────────────────────────
  Meeting copyWith({
    String? title,
    String? description,
    DateTime? scheduledAt,
    int? durationMinutes,
    List<String>? participants,
    String? transcript,
    MeetingStatus? status,
    MeetingPriority? priority,
    List<String>? tags,
    TriageResult? triageResult,
    bool clearTriageResult = false,
    String? relativeTime,
    String? audioDuration,
    String? progressText,
    double? progressPercent,
    String? syncStatusText,
  }) {
    return Meeting(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      participants: participants ?? this.participants,
      transcript: transcript ?? this.transcript,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      triageResult:
          clearTriageResult ? null : (triageResult ?? this.triageResult),
      relativeTime: relativeTime ?? this.relativeTime,
      audioDuration: audioDuration ?? this.audioDuration,
      progressText: progressText ?? this.progressText,
      progressPercent: progressPercent ?? this.progressPercent,
      syncStatusText: syncStatusText ?? this.syncStatusText,
    );
  }

  // ── JSON ──────────────────────────────────────────────────────────────────
  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as String?,
      title: (json['title'] as String?) ?? 'Untitled',
      description: (json['description'] as String?) ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : DateTime.now(),
      durationMinutes: (json['durationMinutes'] as int?) ?? 60,
      participants: ((json['participants'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      transcript: json['transcript'] as String?,
      status: MeetingStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => MeetingStatus.scheduled,
      ),
      priority: MeetingPriority.values.firstWhere(
        (e) => e.name == (json['priority'] as String?),
        orElse: () => MeetingPriority.medium,
      ),
      tags: ((json['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      relativeTime: json['relativeTime'] as String?,
      audioDuration: json['audioDuration'] as String?,
      progressText: json['progressText'] as String?,
      progressPercent: (json['progressPercent'] as num?)?.toDouble(),
      syncStatusText: json['syncStatusText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'participants': participants,
        'transcript': transcript,
        'status': status.name,
        'priority': priority.name,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'relativeTime': relativeTime,
        'audioDuration': audioDuration,
        'progressText': progressText,
        'progressPercent': progressPercent,
        'syncStatusText': syncStatusText,
      };
}
