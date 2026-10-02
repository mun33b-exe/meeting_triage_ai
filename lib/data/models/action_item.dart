import 'package:uuid/uuid.dart';

enum ActionPriority { low, medium, high }

/// A single task produced by an AI triage pass.
/// `isCompleted` is mutable so the provider can toggle it in-place.
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
    this.meetingTitle,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String meetingId;
  final String title;
  final String assignedTo;
  final DateTime? dueDate;
  bool isCompleted;
  final ActionPriority priority;
  final DateTime createdAt;
  final String? meetingTitle;

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  String get priorityLabel {
    switch (priority) {
      case ActionPriority.high:
        return 'High';
      case ActionPriority.medium:
        return 'Med';
      case ActionPriority.low:
        return 'Low';
    }
  }

  ActionItem copyWith({
    String? title,
    String? assignedTo,
    DateTime? dueDate,
    bool? isCompleted,
    ActionPriority? priority,
    String? meetingTitle,
  }) {
    return ActionItem(
      id: id,
      meetingId: meetingId,
      title: title ?? this.title,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      meetingTitle: meetingTitle ?? this.meetingTitle,
    );
  }

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
      meetingTitle: json['meetingTitle'] as String?,
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
        'meetingTitle': meetingTitle,
      };
}
