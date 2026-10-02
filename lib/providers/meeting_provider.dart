import 'package:flutter/foundation.dart';

import '../data/models/action_item.dart';
import '../data/models/meeting.dart';
import '../data/models/triage_result.dart';
import '../services/gemini_service.dart';

/// Single source of truth for the entire MVP.
/// Manages: meeting list, active-meeting selection, triage async state,
/// action-item toggles, and KPI aggregates matching Stitch design.
class MeetingProvider extends ChangeNotifier {
  MeetingProvider(this._gemini) {
    _meetings = _buildMockMeetings();
  }

  final GeminiService _gemini;

  late List<Meeting> _meetings;
  bool _isAnalyzing = false;
  String? _error;
  String? _activeMeetingId;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Meeting> get meetings => List.unmodifiable(_meetings);
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  bool get isLive => _gemini.isLive;

  Meeting? get activeMeeting {
    if (_activeMeetingId == null) return null;
    try {
      return _meetings.firstWhere((m) => m.id == _activeMeetingId);
    } catch (_) {
      return null;
    }
  }

  // ── KPI aggregates ────────────────────────────────────────────────────────

  int get totalMeetings => _meetings.length;

  int get completedMeetings => _meetings
      .where((m) =>
          m.status == MeetingStatus.completed ||
          m.status == MeetingStatus.synced)
      .length;

  double get recordedHours {
    final minutes =
        _meetings.fold<int>(0, (sum, m) => sum + m.durationMinutes);
    return double.parse((minutes / 60.0).toStringAsFixed(1));
  }

  int get processedMeetings =>
      _meetings.where((m) => m.triageResult != null).length;

  int get processedPercentage {
    if (_meetings.isEmpty) return 0;
    return ((processedMeetings / _meetings.length) * 100).round();
  }

  String get processedStatusText {
    if (_meetings.isEmpty) return 'No meetings';
    if (processedPercentage == 100) return 'All synthesized';
    final remaining = _meetings.length - processedMeetings;
    if (remaining == 0) return 'All synthesized';
    return '$remaining pending triage';
  }

  int get _totalActionItems => _meetings
      .expand((m) => m.triageResult?.actionItems ?? <ActionItem>[])
      .length;

  int get pendingActionItems => _meetings
      .expand((m) => m.triageResult?.actionItems ?? <ActionItem>[])
      .where((a) => !a.isCompleted)
      .length;

  int get completedActionItems => _meetings
      .expand((m) => m.triageResult?.actionItems ?? <ActionItem>[])
      .where((a) => a.isCompleted)
      .length;

  int get actionsDueToday => _meetings
      .expand((m) => m.triageResult?.actionItems ?? <ActionItem>[])
      .where((a) => !a.isCompleted && a.isDueToday)
      .length;

  /// 0.0–1.0; returns 0.0 when there are no action items.
  double get actionCompletionRate {
    final total = _totalActionItems;
    return total == 0 ? 0.0 : completedActionItems / total;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void setActiveMeeting(String? meetingId) {
    _activeMeetingId = meetingId;
    notifyListeners();
  }

  /// Creates a new meeting from [title] + [notes] and runs the AI triage.
  Future<void> analyzeNewMeeting({
    required String title,
    required String notes,
    List<String> participants = const [],
  }) async {
    _isAnalyzing = true;
    _error = null;

    final newMeeting = Meeting(
      title: title.trim().isEmpty ? 'Ad-hoc Analysis' : title.trim(),
      description: notes,
      scheduledAt: DateTime.now(),
      durationMinutes: 60,
      participants: participants,
      transcript: notes,
      status: MeetingStatus.needsTriage,
      priority: MeetingPriority.medium,
      relativeTime: 'Just now',
      audioDuration: '4:12',
      progressText: '0 of 3 items drafted',
      progressPercent: 0.0,
      tags: const ['#adhoc', '#triage'],
    );

    _meetings = [newMeeting, ..._meetings];
    _activeMeetingId = newMeeting.id;
    notifyListeners();

    try {
      final result = await _gemini.analyzeMeeting(newMeeting, notes);
      _replaceMeetingResult(newMeeting.id, result);
    } catch (e) {
      _error = 'Analysis failed — please try again.';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Re-runs triage for an existing [meeting] with updated [notes].
  Future<void> reAnalyzeMeeting(Meeting meeting, String notes) async {
    _isAnalyzing = true;
    _error = null;
    _activeMeetingId = meeting.id;
    notifyListeners();

    try {
      final updated = meeting.copyWith(
        transcript: notes.trim().isNotEmpty ? notes : meeting.transcript,
      );
      final idx = _meetings.indexWhere((m) => m.id == meeting.id);
      if (idx != -1) {
        _meetings = List.from(_meetings)..[idx] = updated;
      }

      final result = await _gemini.analyzeMeeting(updated, notes);
      _replaceMeetingResult(meeting.id, result);
    } catch (e) {
      _error = 'Re-analysis failed — please try again.';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  List<ActionItem> get allActionItems {
    final list = <ActionItem>[];
    for (final m in _meetings) {
      final items = m.triageResult?.actionItems ?? [];
      for (final a in items) {
        list.add(a.copyWith(meetingTitle: m.title));
      }
    }
    return list;
  }

  /// Flips `isCompleted` on a single action item in-place and updates meeting metrics.
  void toggleActionItem(String meetingId, String actionItemId) {
    final mIdx = _meetings.indexWhere((m) => m.id == meetingId);
    if (mIdx == -1) return;
    final items = _meetings[mIdx].triageResult?.actionItems;
    if (items == null) return;
    final aIdx = items.indexWhere((a) => a.id == actionItemId);
    if (aIdx == -1) return;
    items[aIdx].isCompleted = !items[aIdx].isCompleted;

    final completedCount = items.where((a) => a.isCompleted).length;
    final totalCount = items.length;
    final percent = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final isAllCompleted = completedCount == totalCount && totalCount > 0;

    _meetings[mIdx] = _meetings[mIdx].copyWith(
      progressPercent: percent,
      progressText: '$completedCount of $totalCount items completed',
      status: isAllCompleted && _meetings[mIdx].status != MeetingStatus.synced
          ? MeetingStatus.completed
          : _meetings[mIdx].status,
    );
    notifyListeners();
  }

  /// Marks a meeting as synced to Linear with updated progress indicators.
  void syncMeetingToLinear(String meetingId) {
    final idx = _meetings.indexWhere((m) => m.id == meetingId);
    if (idx == -1) return;
    final meeting = _meetings[idx];
    final itemsCount = meeting.triageResult?.actionItems.length ?? 0;
    final updated = meeting.copyWith(
      status: MeetingStatus.synced,
      syncStatusText: 'Synced to Linear & Jira',
      progressPercent: 1.0,
      progressText: '$itemsCount of $itemsCount synced to Linear',
    );
    _meetings = List.from(_meetings)..[idx] = updated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _replaceMeetingResult(String meetingId, TriageResult result) {
    final idx = _meetings.indexWhere((m) => m.id == meetingId);
    if (idx == -1) return;
    _meetings = List.from(_meetings)
      ..[idx] = _meetings[idx].copyWith(triageResult: result);
  }

  // ── Seed data matching Stitch design ──────────────────────────────────────

  List<Meeting> _buildMockMeetings() {
    const m1 = 'mock-adhoc-001';
    const m2 = 'mock-q4-roadmap-002';
    const m3 = 'mock-security-audit-003';

    return [
      // ── Card 1: Needs Review (Ad-hoc Analysis) ────────────────────────────
      Meeting(
        id: m1,
        title: 'Ad-hoc Analysis',
        description:
            'Aligned on Q4 infrastructure budget and finalized multi-region deployment schedule. Key risk flagged around vendor SLA commitments and failover testing.',
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 12)),
        durationMinutes: 60,
        participants: ['Sarah Chen', 'Marcus Rivera', 'Tom Walsh'],
        status: MeetingStatus.needsTriage,
        priority: MeetingPriority.medium,
        tags: ['#infrastructure', '#budget', '#q4'],
        relativeTime: '12m ago',
        audioDuration: '4:12',
        progressText: '0 of 3 items drafted',
        progressPercent: 0.0,
        transcript:
            'We reviewed the infrastructure requirements for multi-region deployment and finalized the vendor budget allocations for Q4. Team highlighted key risk around vendor SLA commitments and failover testing.',
        triageResult: TriageResult(
          meetingId: m1,
          summary:
              'Aligned on Q4 infrastructure budget and finalized multi-region deployment schedule. Key risk flagged around vendor SLA commitments and failover testing.',
          keyDecisions: [
            'Finalized Q4 multi-region cloud budget allocation',
            'Deployment timeline locked to November rollout',
            'Failover testing slated for staging verification',
          ],
          actionItems: [
            ActionItem(
              meetingId: m1,
              title: 'Draft vendor SLA commitment terms',
              assignedTo: 'Sarah Chen',
              dueDate: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                17,
                0,
              ),
              priority: ActionPriority.high,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m1,
              title: 'Setup multi-region failover testing pipeline',
              assignedTo: 'Marcus Rivera',
              dueDate: DateTime.now().add(const Duration(days: 5)),
              priority: ActionPriority.medium,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m1,
              title: 'Prepare budget adjustment memo for finance',
              assignedTo: 'Tom Walsh',
              dueDate: DateTime.now().add(const Duration(days: 7)),
              priority: ActionPriority.low,
              isCompleted: false,
            ),
          ],
          riskFlags: [
            'Vendor SLA commitments are pending legal signoff',
            'Cross-region network latency risk during failover',
          ],
          suggestedFollowUp:
              'Check in with cloud vendor rep on Thursday to lock revised SLA terms.',
          sentimentScore: 0.75,
          priorityScore: 78,
          modelUsed: 'mock',
        ),
      ),

      // ── Card 2: Partially Synced (Q4 Product Roadmap Planning) ────────────
      Meeting(
        id: m2,
        title: 'Q4 Product Roadmap Planning',
        description:
            'Locked beta launch date to Oct 28th. Assigned feature ownership to frontend & backend leads. PRD updated with bi-weekly sync checkpoints.',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 3)),
        durationMinutes: 75,
        participants: [
          'Alex Lee',
          'Sarah Rivera',
          'Marcus Rivera',
          'Priya Patel',
          'Tom Walsh'
        ],
        status: MeetingStatus.inProgress,
        priority: MeetingPriority.high,
        tags: ['#product', '#roadmap', '#planning'],
        relativeTime: '3h ago',
        audioDuration: '5:30',
        progressText: '1 of 4 synced to Linear',
        progressPercent: 0.25,
        transcript:
            'Locked beta launch date to Oct 28th. Assigned feature ownership to frontend & backend leads. PRD updated with bi-weekly sync checkpoints.',
        triageResult: TriageResult(
          meetingId: m2,
          summary:
              'Locked beta launch date to Oct 28th. Assigned feature ownership to frontend & backend leads. PRD updated with bi-weekly sync checkpoints.',
          keyDecisions: [
            'Beta launch locked to October 28th — non-negotiable',
            'Weekly engineering syncs begin Monday at 10 AM',
            'Marketing plan due by October 15th',
            'Design sign-off required before engineering starts integration',
          ],
          actionItems: [
            ActionItem(
              meetingId: m2,
              title: 'Finalise and publish UX specifications',
              assignedTo: 'Sarah Rivera',
              dueDate: DateTime.now().add(const Duration(days: 5)),
              priority: ActionPriority.high,
              isCompleted: true,
            ),
            ActionItem(
              meetingId: m2,
              title: 'Sync backlog tickets directly to Linear roadmap',
              assignedTo: 'Marcus Rivera',
              dueDate: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                18,
                0,
              ),
              priority: ActionPriority.medium,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m2,
              title: 'Draft and distribute marketing launch plan',
              assignedTo: 'Priya Patel',
              dueDate: DateTime.now().add(const Duration(days: 14)),
              priority: ActionPriority.high,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m2,
              title: 'Create timeline contingency plan document',
              assignedTo: 'Tom Walsh',
              dueDate: DateTime.now().add(const Duration(days: 7)),
              priority: ActionPriority.medium,
              isCompleted: false,
            ),
          ],
          riskFlags: [
            'Tight October 28th deadline with multiple upstream dependencies',
            'No contingency plan yet for scope changes',
          ],
          suggestedFollowUp:
              'Schedule a mid-point check-in on October 14th to review all action items and surface blockers early.',
          sentimentScore: 0.81,
          priorityScore: 88,
          modelUsed: 'mock',
        ),
      ),

      // ── Card 3: Completed / Synced (Infrastructure Security Audit) ────────
      Meeting(
        id: m3,
        title: 'Infrastructure Security Audit',
        description:
            'Zero-day remediation verified across staging environments. Sign-off completed; awaiting final automated notification push.',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 5)),
        durationMinutes: 45,
        participants: ['James Liu', 'Anika Sharma'],
        status: MeetingStatus.synced,
        priority: MeetingPriority.critical,
        tags: ['#security', '#audit'],
        relativeTime: '5h ago',
        audioDuration: '3:15',
        progressText: '2 of 2 items completed',
        progressPercent: 1.0,
        syncStatusText: 'Synced to Linear & Jira',
        transcript:
            'Zero-day remediation verified across staging environments. Sign-off completed; awaiting final automated notification push.',
        triageResult: TriageResult(
          meetingId: m3,
          summary:
              'Zero-day remediation verified across staging environments. Sign-off completed; awaiting final automated notification push.',
          keyDecisions: [
            'Zero-day remediation verified across staging',
            'Automated notification pipeline scheduled',
            'All compliance checkboxes fulfilled',
          ],
          actionItems: [
            ActionItem(
              meetingId: m3,
              title: 'Deploy SQL injection patches to production servers',
              assignedTo: 'James Liu',
              dueDate: DateTime.now().add(const Duration(hours: 24)),
              priority: ActionPriority.high,
              isCompleted: true,
            ),
            ActionItem(
              meetingId: m3,
              title: 'Renew and update all TLS certificates',
              assignedTo: 'Anika Sharma',
              dueDate: DateTime.now().add(const Duration(days: 3)),
              priority: ActionPriority.high,
              isCompleted: true,
            ),
          ],
          riskFlags: [
            'Final push notification awaits DevOps automated trigger',
          ],
          suggestedFollowUp:
              'Check automated Slack notification in #ops-alerts at 14:00 UTC.',
          sentimentScore: 0.94,
          priorityScore: 95,
          modelUsed: 'mock',
        ),
      ),
    ];
  }
}
