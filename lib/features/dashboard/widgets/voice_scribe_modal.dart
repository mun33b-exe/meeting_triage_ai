import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/meeting.dart';
import '../../triage/triage_screen.dart';

/// Modal bottom sheet simulating a live voice recording debrief with waveform
/// visualizer, live timer, and instant transcription to TriageScreen.
class VoiceScribeModal extends StatefulWidget {
  const VoiceScribeModal({super.key, this.initialMeeting});

  final Meeting? initialMeeting;

  static Future<void> show(BuildContext context, {Meeting? meeting}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceScribeModal(initialMeeting: meeting),
    );
  }

  @override
  State<VoiceScribeModal> createState() => _VoiceScribeModalState();
}

class _VoiceScribeModalState extends State<VoiceScribeModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  Timer? _timer;
  int _secondsElapsed = 4; // Start at 00:04 for immediate live feel

  final List<String> _speakers = [
    'Alex (Lead): Let\'s lock the multi-region deployment schedule for Q4 and address vendor SLA terms.',
    'Sarah (DevOps): Current vendor SLA is 4h; we need 15m response on Sev-1 incidents.',
    'Marcus (Backend): Staging failover tests between us-east and eu-central must pass before Oct 28.',
    'Tom (PM): I\'ll draft the budget adjustment memo and follow up with legal by Thursday.',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onStopAndTranscribe() {
    _timer?.cancel();
    Navigator.pop(context); // Close bottom sheet

    // If an existing meeting was passed in, pass it to triage; otherwise generate simulated meeting
    final meeting = widget.initialMeeting ??
        Meeting(
          title: 'Executive Sync & Deployment Blockers',
          description:
              'Multi-region deployment review, cloud vendor SLA guarantees, and staging failover testing sign-off.',
          scheduledAt: DateTime.now(),
          durationMinutes: 45,
          participants: const [
            'Alex Lee',
            'Sarah Rivera',
            'Marcus Rivera',
            'Tom Walsh'
          ],
          status: MeetingStatus.needsTriage,
          priority: MeetingPriority.high,
          tags: const ['#deployment', '#sla', '#infrastructure'],
          relativeTime: 'Just recorded',
          audioDuration: _formattedTime,
          transcript: '''
Alex (Lead): Let's lock the multi-region deployment schedule for Q4 and address the vendor SLA terms. What are our hard blockers?

Sarah (DevOps): Current vendor SLA response time is 4 hours; for Sev-1 incidents, our enterprise tier requires 15-minute response.

Marcus (Backend): Staging failover tests between us-east and eu-central must pass before October 28th.

Tom (Product): I'll draft the budget adjustment memo and follow up with vendor legal on revised SLA terms by Thursday.''',
        );

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TriageScreen(meeting: meeting),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF16181F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0x26FFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Top Status & Live indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RECORDING LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mic_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Instant Scribe AI',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Timer
            Text(
              _formattedTime,
              style: GoogleFonts.inter(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Listening to multi-speaker conversation...',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Animated Audio Waveform Visualizer
            SizedBox(
              height: 52,
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(26, (i) {
                      final wave = math.sin((_animCtrl.value * math.pi * 2) +
                          (i * 0.45));
                      final height =
                          (12 + (wave.abs() * 36)).clamp(8.0, 48.0);
                      return Container(
                        width: 3.5,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 2.2),
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? AppColors.primary
                              : AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Simulated Live Captions / Transcription Stream
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x10FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stream_rounded,
                          size: 13, color: AppColors.outline),
                      const SizedBox(width: 5),
                      Text(
                        'SPEAKER DETECTION STREAM',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._speakers.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        s,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Controls: Cancel & Stop/Transcribe
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      _timer?.cancel();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0x20FFFFFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Discard',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _onStopAndTranscribe,
                    icon: const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: Colors.white),
                    label: Text(
                      'Stop & Transcribe',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
