import 'package:flutter/foundation.dart';

import '../data/models/action_item.dart';
import '../data/models/meeting.dart';
import '../data/models/triage_result.dart';
import '../services/gemini_service.dart';

/// Single source of truth for the entire MVP.
/// Manages: meeting list, active-meeting selection, triage async state,
/// action-item toggles, and KPI aggregates.
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

  int get completedMeetings =>
      _meetings.where((m) => m.status == MeetingStatus.completed).length;

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
      status: MeetingStatus.completed,
      priority: MeetingPriority.medium,
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
      // Persist updated transcript before sending to the model.
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

  /// Flips `isCompleted` on a single action item in-place (O(n) lookup, O(1)
  /// mutation) then notifies listeners so the checkbox animates immediately.
  void toggleActionItem(String meetingId, String actionItemId) {
    final mIdx = _meetings.indexWhere((m) => m.id == meetingId);
    if (mIdx == -1) return;
    final items = _meetings[mIdx].triageResult?.actionItems;
    if (items == null) return;
    final aIdx = items.indexWhere((a) => a.id == actionItemId);
    if (aIdx == -1) return;
    items[aIdx].isCompleted = !items[aIdx].isCompleted;
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

  // ── Seed data ─────────────────────────────────────────────────────────────

  List<Meeting> _buildMockMeetings() {
    const m1 = 'mock-q4-roadmap-001';
    const m2 = 'mock-security-audit-002';

    return [
      Meeting(
        id: m1,
        title: 'Q4 Product Roadmap Planning',
        description:
            'Quarterly planning to align on product priorities, resource '
            'allocation, and delivery milestones for Q4 2026.',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 3)),
        durationMinutes: 75,
        participants: ['Sarah Chen', 'Marcus Rivera', 'Priya Patel', 'Tom Walsh'],
        status: MeetingStatus.completed,
        priority: MeetingPriority.high,
        tags: ['product', 'planning', 'Q4'],
        transcript:
            'We discussed the Q4 roadmap and agreed the beta launch will happen '
            'October 28th. Sarah will finalise UX specs by next Friday. Marcus '
            'confirmed engineering is available and will set up weekly syncs '
            'starting Monday. Priya will draft the marketing plan by October 15th. '
            'Tom raised concerns about the timeline being tight and suggested a '
            'contingency plan.',
        triageResult: TriageResult(
          meetingId: m1,
          summary:
              'Team successfully aligned on Q4 priorities with the beta launch '
              'locked to October 28th. Clear ownership was established across '
              'design, engineering, and marketing with firm deliverable dates.',
          keyDecisions: [
            'Beta launch locked to October 28th — non-negotiable',
            'Weekly engineering syncs begin Monday at 10 AM',
            'Marketing plan due by October 15th',
            'Design sign-off required before engineering starts integration',
          ],
          actionItems: [
            ActionItem(
              meetingId: m1,
              title: 'Finalise and publish UX specifications',
              assignedTo: 'Sarah Chen',
              dueDate: DateTime.now().add(const Duration(days: 5)),
              priority: ActionPriority.high,
              isCompleted: true,
            ),
            ActionItem(
              meetingId: m1,
              title: 'Schedule recurring weekly engineering sync (Mon 10 AM)',
              assignedTo: 'Marcus Rivera',
              dueDate: DateTime.now().add(const Duration(days: 2)),
              priority: ActionPriority.medium,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m1,
              title: 'Draft and distribute marketing launch plan',
              assignedTo: 'Priya Patel',
              dueDate: DateTime.now().add(const Duration(days: 14)),
              priority: ActionPriority.high,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m1,
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
              'Schedule a mid-point check-in on October 14th to review all '
              'action items and surface blockers early.',
          sentimentScore: 0.81,
          priorityScore: 88,
          modelUsed: 'mock',
        ),
      ),

      Meeting(
        id: m2,
        title: 'Infrastructure Security Audit Review',
        description:
            'Bi-annual security audit results review. Identify critical '
            'vulnerabilities and define remediation timelines.',
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        durationMinutes: 45,
        participants: ['James Liu', 'Anika Sharma', 'DevOps Team'],
        status: MeetingStatus.completed,
        priority: MeetingPriority.critical,
        tags: ['security', 'infrastructure', 'audit'],
        transcript:
            'The security audit identified two critical vulnerabilities: SQL '
            'injection risk in legacy API endpoints and outdated TLS certs across '
            '3 services. James confirmed patches are ready for immediate '
            'deployment. Anika will update all TLS certs by Friday EOD. The team '
            'agreed to implement automated certificate rotation to prevent '
            'recurrence.',
        triageResult: TriageResult(
          meetingId: m2,
          summary:
              'Audit uncovered two critical production vulnerabilities requiring '
              'immediate remediation. SQL injection patches are deployment-ready; '
              'TLS certificate updates scheduled for Friday. Automation measures '
              'approved to prevent future certificate lapses.',
          keyDecisions: [
            'SQL injection patches to be deployed within 24 hours',
            'All TLS certificates updated by Friday EOD',
            'Automated certificate rotation pipeline to be implemented',
            'Weekly automated security scan reports to be introduced',
          ],
          actionItems: [
            ActionItem(
              meetingId: m2,
              title: 'Deploy SQL injection patches to production servers',
              assignedTo: 'James Liu',
              dueDate: DateTime.now().add(const Duration(hours: 24)),
              priority: ActionPriority.high,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m2,
              title: 'Renew and update all TLS certificates',
              assignedTo: 'Anika Sharma',
              dueDate: DateTime.now().add(const Duration(days: 3)),
              priority: ActionPriority.high,
              isCompleted: false,
            ),
            ActionItem(
              meetingId: m2,
              title: 'Implement automated certificate rotation pipeline',
              assignedTo: 'DevOps Team',
              dueDate: DateTime.now().add(const Duration(days: 14)),
              priority: ActionPriority.medium,
              isCompleted: false,
            ),
          ],
          riskFlags: [
            'Active SQL injection vulnerability in production — patch urgently',
            'Expired TLS certs affecting 3 live services',
            'No automated monitoring was in place prior to this audit',
          ],
          suggestedFollowUp:
              'Verify patch deployment and run full regression test suite within '
              '48 hours. Schedule post-remediation review for next week.',
          sentimentScore: 0.42,
          priorityScore: 97,
          modelUsed: 'mock',
        ),
      ),
    ];
  }
}
