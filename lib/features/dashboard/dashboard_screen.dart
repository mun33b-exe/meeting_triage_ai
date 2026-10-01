import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/meeting.dart';
import '../../providers/meeting_provider.dart';
import '../triage/triage_screen.dart';

/// Screen 1 — Dashboard
/// Shows KPI stats row, recent-meetings feed, and a FAB to start a new triage.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ── Routing helper ────────────────────────────────────────────────────────

  void _openTriage(BuildContext context, {Meeting? meeting}) {
    if (meeting != null) {
      context.read<MeetingProvider>().setActiveMeeting(meeting.id);
    } else {
      context.read<MeetingProvider>().setActiveMeeting(null);
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TriageScreen(meeting: meeting),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _SynapseAppBar(onNewTriage: () => _openTriage(context)),
          SliverToBoxAdapter(
            child: Responsive.constrainedContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _GreetingHeader(),
                  const SizedBox(height: 24),
                  _StatsRow(),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Recent Meetings',
                    subtitle: 'AI-triaged & ready to review',
                  ),
                  const SizedBox(height: 14),
                  _MeetingsList(
                    onViewTriage: (m) => _openTriage(context, meeting: m),
                  ),
                  const SizedBox(height: 100), // FAB clearance
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _NewTriageFAB(
        onTap: () => _openTriage(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SliverAppBar
// ─────────────────────────────────────────────────────────────────────────────

class _SynapseAppBar extends StatelessWidget {
  const _SynapseAppBar({required this.onNewTriage});
  final VoidCallback onNewTriage;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Logo
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Synapse AI',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Meeting Intelligence',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _AiStatusBadge(),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border.withValues(alpha: 0.35)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI-status pill
// ─────────────────────────────────────────────────────────────────────────────

class _AiStatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLive = context.watch<MeetingProvider>().isLive;
    final color = isLive ? AppColors.success : AppColors.accent;
    final label = isLive ? 'AI Live' : 'Mock Mode';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting header
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's your operations intelligence summary.",
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI stats row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MeetingProvider>();

    final stats = [
      _StatData('Total Meetings', p.totalMeetings.toString(),
          Icons.calendar_today_rounded, AppColors.accent),
      _StatData('Completed', p.completedMeetings.toString(),
          Icons.check_circle_rounded, AppColors.success),
      _StatData('Open Actions', p.pendingActionItems.toString(),
          Icons.pending_actions_rounded, AppColors.warning),
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _StatCard(stats[i]),
          ),
        ],
      ],
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.data);
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 15),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.value,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.label,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meetings feed
// ─────────────────────────────────────────────────────────────────────────────

class _MeetingsList extends StatelessWidget {
  const _MeetingsList({required this.onViewTriage});
  final void Function(Meeting) onViewTriage;

  @override
  Widget build(BuildContext context) {
    final meetings = context.watch<MeetingProvider>().meetings;

    if (meetings.isEmpty) return _EmptyState();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: meetings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MeetingCard(
        meeting: meetings[i],
        onViewTriage: () => onViewTriage(meetings[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meeting card
// ─────────────────────────────────────────────────────────────────────────────

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting, required this.onViewTriage});
  final Meeting meeting;
  final VoidCallback onViewTriage;

  Color get _priorityColor {
    switch (meeting.priority) {
      case MeetingPriority.low:
        return AppColors.success;
      case MeetingPriority.medium:
        return AppColors.warning;
      case MeetingPriority.high:
        return AppColors.danger;
      case MeetingPriority.critical:
        return AppColors.dangerDeep;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final result = meeting.triageResult;
    final totalA = result?.actionItems.length ?? 0;
    final doneA =
        result?.actionItems.where((a) => a.isCompleted).length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.55), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority accent bar
              Container(width: 4, color: _priorityColor),
              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title row ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              meeting.title,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriorityBadge(meeting.priority),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // ── Meta row ──
                      Row(
                        children: [
                          _MetaChip(Icons.schedule_rounded,
                              _timeAgo(meeting.scheduledAt)),
                          const SizedBox(width: 12),
                          _MetaChip(Icons.timer_rounded,
                              '${meeting.durationMinutes}m'),
                          const SizedBox(width: 12),
                          _MetaChip(Icons.group_rounded,
                              '${meeting.participants.length}'),
                        ],
                      ),
                      // ── AI summary ──
                      if (result != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          result.summary,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Action-item progress bar
                        if (totalA > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Actions $doneA/$totalA',
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                              Text(
                                '${((doneA / totalA) * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: doneA / totalA,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                doneA == totalA
                                    ? AppColors.success
                                    : AppColors.accent,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      // ── Footer ──
                      Row(
                        children: [
                          ...meeting.tags.take(2).map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _TagChip(t),
                                ),
                              ),
                          const Spacer(),
                          _TriageButton(
                              hasResult: result != null,
                              onTap: onViewTriage),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Micro-widgets used inside _MeetingCard
// ─────────────────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(label,
            style:
                GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge(this.priority);
  final MeetingPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      MeetingPriority.low => ('LOW', AppColors.success),
      MeetingPriority.medium => ('MED', AppColors.warning),
      MeetingPriority.high => ('HIGH', AppColors.danger),
      MeetingPriority.critical => ('CRIT', AppColors.dangerDeep),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.tag);
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TriageButton extends StatelessWidget {
  const _TriageButton({required this.hasResult, required this.onTap});
  final bool hasResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: hasResult ? AppColors.accentGradient : null,
          color: hasResult ? null : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: hasResult
              ? null
              : Border.all(color: AppColors.border, width: 1),
          boxShadow: hasResult
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasResult
                  ? Icons.auto_awesome
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              hasResult ? 'View Triage' : 'Analyse',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No meetings yet',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "New Triage" to run your first AI analysis.',
            style:
                GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB
// ─────────────────────────────────────────────────────────────────────────────

class _NewTriageFAB extends StatelessWidget {
  const _NewTriageFAB({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 17),
                const SizedBox(width: 8),
                Text(
                  'New Triage',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
