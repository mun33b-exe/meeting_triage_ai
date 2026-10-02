import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_triage_ai/providers/meeting_provider.dart';
import 'package:meeting_triage_ai/services/gemini_service.dart';

void main() {
  group('MeetingProvider Dynamic KPI Calculations', () {
    test('Calculates live meeting counts and recorded hours', () {
      final provider = MeetingProvider(GeminiService());

      expect(provider.totalMeetings, 3);
      expect(provider.recordedHours, 3.0);
      expect(provider.processedMeetings, 3);
      expect(provider.processedPercentage, 100);
      expect(provider.processedStatusText, 'All synthesized');
    });

    test('Calculates pending action items and due today count dynamically', () {
      final provider = MeetingProvider(GeminiService());

      // Seed meetings: 3 in m1 (all uncompleted), 4 in m2 (1 completed), 2 in m3 (2 completed)
      // Total uncompleted: 3 + 3 + 0 = 6
      expect(provider.pendingActionItems, 6);
      expect(provider.completedActionItems, 3);
      expect(provider.actionsDueToday, 2);

      // Toggle an action item that is due today
      final dueTodayItem = provider.allActionItems.firstWhere(
        (a) => !a.isCompleted && a.isDueToday,
      );
      provider.toggleActionItem(dueTodayItem.meetingId, dueTodayItem.id);

      // Now pending drops to 5, due today drops to 1, completed rises to 4
      expect(provider.pendingActionItems, 5);
      expect(provider.actionsDueToday, 1);
      expect(provider.completedActionItems, 4);

      // Toggle the second due today action item
      final secondDueItem = provider.allActionItems.firstWhere(
        (a) => !a.isCompleted && a.isDueToday,
      );
      provider.toggleActionItem(secondDueItem.meetingId, secondDueItem.id);

      // Now due today drops to 0
      expect(provider.actionsDueToday, 0);
      expect(provider.pendingActionItems, 4);
      expect(provider.completedActionItems, 5);
    });
  });
}
