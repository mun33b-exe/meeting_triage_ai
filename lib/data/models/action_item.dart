import 'package:uuid/uuid.dart';

enum ActionPriority { low, medium, high }

/// A single task produced by an AI triage pass.
/// `isCompleted` is intentionally mutable so the provider can toggle it
/// in-place without rebuilding the whole meeting object graph.
class ActionItem {
  ActionItem({
    String? id,
    required this.meetingId,
    required this.title,
    required this.assignedTo,
    this.dueDate,
    this.isCompleted = false,
    this.priority = ActionPriority.medium,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String meetingId;
  final String title;
  final String assignedTo;
  final DateTime? dueDate;
  bool isCompleted; // mutable — toggled via MeetingProvider.toggleActionItem
  final ActionPriority priority;
  final DateTime createdAt;

  factory ActionItem.fromJson(Map<String, dynamic> json, String meetingId) {
    return ActionItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      meetingId: meetingId,
      title: (json['title'] as String?) ?? 'Untitled action',
      assignedTo: (json['assignedTo'] as String?) ?? 'Unassigned',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      priority: ActionPriority.values.firstWhere(
        (e) => e.name == (json['priority'] as String?),
        orElse: () => ActionPriority.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'meetingId': meetingId,
        'title': title,
        'assignedTo': assignedTo,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
      };
}
