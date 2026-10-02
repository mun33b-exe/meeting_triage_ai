import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/action_item.dart';
import '../../data/models/meeting.dart';
import '../../data/models/triage_result.dart';
import '../../providers/meeting_provider.dart';

/// Screen 2 — AI Triage
/// • Input section: meeting-context banner (existing) or title field (new),
///   quick-fill chips, multi-line notes field, Analyse button.
/// • Loading state: shimmer skeleton cards.
/// • Results: summary, key decisions, action items (interactive), risks,
///   and suggested follow-up.
class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key, this.meeting});
  final Meeting? meeting;

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _scroll = ScrollController();

  bool _showResults = false;

  static const List<String> _chips = [
    'Discussed product roadmap',
    'Agreed on beta launch date',
    'Action: review design specs',
    'Risk: timeline is tight',
    'Stakeholder sign-off required',
    'Budget approved for Q4',
    'Weekly syncs agreed',
    'Follow-up meeting needed',
    'Team capacity constrained',
    'Milestone accepted by all',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.meeting case final m?) {
      _titleCtrl.text = m.title;
      _notesCtrl.text = m.transcript ?? m.description;
      if (m.triageResult != null) _showResults = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Analysis trigger ──────────────────────────────────────────────────────

  Future<void> _runAnalysis() async {
    final notes = _notesCtrl.text.trim();
    if (notes.isEmpty) {
      _showSnack('Please add meeting notes or a transcript first.',
          AppColors.warning);
      return;
    }

    final provider = context.read<MeetingProvider>();

    if (widget.meeting case final m?) {
      await provider.reAnalyzeMeeting(m, notes);
    } else {
      await provider.analyzeNewMeeting(
        title: _titleCtrl.text.trim(),
        notes: notes,
      );
    }

    if (!mounted) return;
    setState(() => _showResults = true);

    // Scroll to results after the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeetingProvider>();
    final analyzing = provider.isAnalyzing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(provider),
      body: SingleChildScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        child: Responsive.constrainedContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildInputSection(analyzing),
              const SizedBox(height: 20),
              if (analyzing) _ShimmerLoader(),
              if (!analyzing && _showResults)
                _ResultsSection(provider: provider),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(MeetingProvider provider) {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 10)
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 9),
          Text(
            'AI Triage',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (provider.isLive ? AppColors.success : AppColors.accent)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (provider.isLive
                      ? AppColors.success
                      : AppColors.accent)
                  .withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            provider.isLive ? 'Gemini Live' : 'Mock Mode',
            style: GoogleFonts.inter(
              color: provider.isLive
                  ? AppColors.success
                  : AppColors.accentLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child:
            Container(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
      ),
    );
  }

  // ── Input section ─────────────────────────────────────────────────────────

  Widget _buildInputSection(bool analyzing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Context header
        if (widget.meeting != null)
          _MeetingContextBanner(widget.meeting!)
        else ...[
          _FieldLabel('Meeting Title', optional: true),
          const SizedBox(height: 8),
          _InputField(
            controller: _titleCtrl,
            hint: 'e.g. Q4 Planning Session',
            maxLines: 1,
            enabled: !analyzing,
          ),
        ],
        const SizedBox(height: 20),

        // Quick-fill chips
        _FieldLabel('Quick Fill', subtitle: '— tap to append to notes'),
        const SizedBox(height: 8),
        _QuickFillChips(
          chips: _chips,
          enabled: !analyzing,
          onChipTap: (text) {
            final cur = _notesCtrl.text;
            final sep = cur.isNotEmpty && !cur.endsWith('\n') ? '. ' : '';
            _notesCtrl.text = '$cur$sep$text';
            _notesCtrl.selection = TextSelection.collapsed(
              offset: _notesCtrl.text.length,
            );
          },
        ),
        const SizedBox(height: 20),

        // Notes textarea
        _FieldLabel('Meeting Notes / Transcript',
            subtitle: '— paste transcript or key points'),
        const SizedBox(height: 8),
        _InputField(
          controller: _notesCtrl,
          hint: 'e.g. "We discussed the Q4 roadmap and agreed the beta '
              'launches October 28th. Sarah will finalise UX specs by '
              'Friday…"',
          maxLines: 8,
          enabled: !analyzing,
        ),
        const SizedBox(height: 20),

        // Analyse button
        _AnalyseButton(analyzing: analyzing, onTap: _runAnalysis),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MeetingContextBanner extends StatelessWidget {
  const _MeetingContextBanner(this.meeting);
  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${meeting.participants.length} participants · '
                  '${meeting.durationMinutes} min',
                  style: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.optional = false, this.subtitle});
  final String label;
  final bool optional;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 5),
          Text('(optional)',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ],
        if (subtitle != null) ...[
          Text(subtitle!,
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.enabled,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        style: GoogleFonts.inter(
            color: AppColors.textPrimary, fontSize: 14, height: 1.6),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: AppColors.textMuted, fontSize: 14, height: 1.6),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

class _QuickFillChips extends StatelessWidget {
  const _QuickFillChips({
    required this.chips,
    required this.enabled,
    required this.onChipTap,
  });
  final List<String> chips;
  final bool enabled;
  final void Function(String) onChipTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: enabled ? () => onChipTap(chips[i]) : null,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              chips[i],
              style: GoogleFonts.inter(
                color: enabled
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyseButton extends StatelessWidget {
  const _AnalyseButton({required this.analyzing, required this.onTap});
  final bool analyzing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: analyzing ? null : AppColors.accentGradient,
          color: analyzing ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: analyzing
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.42),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: analyzing ? null : onTap,
            splashColor: Colors.white.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (analyzing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent),
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    analyzing ? 'Analysing…' : 'Run AI Analysis',
                    style: GoogleFonts.inter(
                      color: analyzing
                          ? AppColors.textMuted
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer skeleton loader
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Triage Results" label skeleton
          Container(
              width: 140,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              )),
          const SizedBox(height: 16),
          _SkeletonCard(height: 82),
          const SizedBox(height: 12),
          _SkeletonCard(height: 130),
          const SizedBox(height: 12),
          _SkeletonCard(height: 210),
          const SizedBox(height: 12),
          _SkeletonCard(height: 96),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results section
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({required this.provider});
  final MeetingProvider provider;

  @override
  Widget build(BuildContext context) {
    final meeting = provider.activeMeeting;
    final result = meeting?.triageResult;
    if (result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultsHeader(result: result),
        const SizedBox(height: 14),
        _SummaryCard(result: result),
        const SizedBox(height: 12),
        if (result.keyDecisions.isNotEmpty) ...[
          _KeyDecisionsCard(result: result),
          const SizedBox(height: 12),
        ],
        if (result.actionItems.isNotEmpty) ...[
          _ActionItemsCard(
            result: result,
            meetingId: meeting!.id,
            provider: provider,
          ),
          const SizedBox(height: 12),
        ],
        if (result.riskFlags.isNotEmpty) ...[
          _RiskFlagsCard(result: result),
          const SizedBox(height: 12),
        ],
        if (result.suggestedFollowUp.isNotEmpty) ...[
          _FollowUpCard(result: result),
          const SizedBox(height: 16),
        ],
        _OperationalActionsBar(
          meeting: meeting!,
          result: result,
          provider: provider,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results header row
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.result});
  final TriageResult result;

  Color get _scoreColor {
    if (result.priorityScore >= 80) return AppColors.danger;
    if (result.priorityScore >= 50) return AppColors.warning;
    return AppColors.success;
  }

  Color get _sentimentColor {
    if (result.sentimentScore >= 0.65) return AppColors.success;
    if (result.sentimentScore >= 0.4) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 10)
            ],
          ),
          child: const Icon(Icons.analytics_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Triage Results',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'via ${result.modelUsed == "mock" ? "Mock AI" : "Gemini 1.5 Flash"}',
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        // Priority score pill
        _ScorePill(
            icon: Icons.bolt_rounded,
            label: 'P${result.priorityScore}',
            color: _scoreColor),
        const SizedBox(width: 6),
        // Sentiment pill
        _ScorePill(
            icon: Icons.sentiment_satisfied_alt_rounded,
            label: '${(result.sentimentScore * 100).toStringAsFixed(0)}%',
            color: _sentimentColor),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared result card container
// ─────────────────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.border.withValues(alpha: 0.55), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
            child: Row(
              children: [
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 13),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual result cards
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result});
  final TriageResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      icon: Icons.summarize_rounded,
      iconColor: AppColors.accent,
      title: 'Executive Summary',
      child: Text(
        result.summary,
        style: GoogleFonts.inter(
            color: AppColors.textSecondary, fontSize: 13, height: 1.65),
      ),
    );
  }
}

class _KeyDecisionsCard extends StatelessWidget {
  const _KeyDecisionsCard({required this.result});
  final TriageResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      icon: Icons.gavel_rounded,
      iconColor: AppColors.accentLight,
      title: 'Key Decisions',
      child: Column(
        children: result.keyDecisions.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionItemsCard extends StatelessWidget {
  const _ActionItemsCard({
    required this.result,
    required this.meetingId,
    required this.provider,
  });
  final TriageResult result;
  final String meetingId;
  final MeetingProvider provider;

  @override
  Widget build(BuildContext context) {
    final done =
        result.actionItems.where((a) => a.isCompleted).length;

    return _ResultCard(
      icon: Icons.checklist_rounded,
      iconColor: AppColors.success,
      title: 'Action Items',
      trailing: Text(
        '$done/${result.actionItems.length} done',
        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
      ),
      child: Column(
        children: result.actionItems
            .map((item) => _ActionItemTile(
                  item: item,
                  onToggle: () =>
                      provider.toggleActionItem(meetingId, item.id),
                ))
            .toList(),
      ),
    );
  }
}

class _RiskFlagsCard extends StatelessWidget {
  const _RiskFlagsCard({required this.result});
  final TriageResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger,
      title: 'Risk Flags',
      child: Column(
        children: result.riskFlags.map((risk) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    risk,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.result});
  final TriageResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Follow-up',
                  style: GoogleFonts.inter(
                    color: AppColors.accentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  result.suggestedFollowUp,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive action-item tile
// ─────────────────────────────────────────────────────────────────────────────

class _ActionItemTile extends StatelessWidget {
  const _ActionItemTile({required this.item, required this.onToggle});
  final ActionItem item;
  final VoidCallback onToggle;

  String? _dueDateLabel() {
    if (item.dueDate == null) return null;
    return DateFormat('MMM d').format(item.dueDate!);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return 'UN';
  }

  @override
  Widget build(BuildContext context) {
    final (priorityLabel, priorityColor, priorityBg) = switch (item.priority) {
      ActionPriority.low => ('Low', AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      ActionPriority.medium => ('Med', AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      ActionPriority.high => ('High', AppColors.danger, AppColors.danger.withValues(alpha: 0.12)),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: item.isCompleted ? const Color(0x0EFFFFFF) : const Color(0x18FFFFFF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated interactive checkbox
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? AppColors.tertiary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: item.isCompleted
                            ? AppColors.tertiary
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: item.isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.black, size: 12)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Text(
                      item.title,
                      style: GoogleFonts.inter(
                        color: item.isCompleted
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: item.isCompleted ? FontWeight.w400 : FontWeight.w600,
                        height: 1.4,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Assignee with Avatar initials
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x20FFFFFF)),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(item.assignedTo),
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.assignedTo,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_dueDateLabel() != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.outline),
                            const SizedBox(width: 3),
                            Text(
                              _dueDateLabel()!,
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.outline),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        priorityLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: priorityColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Operational Actions Bar: Copy Slack Digest & Sync to Linear
// ─────────────────────────────────────────────────────────────────────────────

class _OperationalActionsBar extends StatefulWidget {
  const _OperationalActionsBar({
    required this.meeting,
    required this.result,
    required this.provider,
  });

  final Meeting meeting;
  final TriageResult result;
  final MeetingProvider provider;

  @override
  State<_OperationalActionsBar> createState() => _OperationalActionsBarState();
}

class _OperationalActionsBarState extends State<_OperationalActionsBar> {
  bool _isSyncing = false;
  bool _showSuccessBanner = false;

  Future<void> _syncToLinear() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      widget.provider.syncMeetingToLinear(widget.meeting.id);
      setState(() {
        _isSyncing = false;
        _showSuccessBanner = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.tertiary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Successfully synced ${widget.result.actionItems.length} issues to Linear Roadmap!',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copySlackDigest() async {
    final m = widget.meeting;
    final r = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('*Synapse AI Executive Digest: ${m.title}*');
    buffer.writeln('📅 ${DateFormat("EEE, MMM d, yyyy").format(m.scheduledAt)} · ${m.durationMinutes} min · ${m.participants.length} attendees\n');
    buffer.writeln('*Executive Summary:*');
    buffer.writeln('${r.summary}\n');
    if (r.keyDecisions.isNotEmpty) {
      buffer.writeln('*Key Decisions:*');
      for (final d in r.keyDecisions) {
        buffer.writeln('• $d');
      }
      buffer.writeln('');
    }
    if (r.actionItems.isNotEmpty) {
      buffer.writeln('*Action Items:*');
      for (final a in r.actionItems) {
        final check = a.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('$check ${a.title} (@${a.assignedTo})');
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.tertiary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Slack digest copied to clipboard!',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSynced = widget.meeting.status == MeetingStatus.synced || _showSuccessBanner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSynced) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.tertiary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Synced to Linear & Jira Roadmap',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tertiary,
                        ),
                      ),
                      Text(
                        '${widget.result.actionItems.length} tasks registered with sprint milestones',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Operational Actions Button Row
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'OPERATIONAL ACTIONS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Copy Slack Digest
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copySlackDigest,
                      icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textPrimary),
                      label: Text(
                        'Copy Slack Digest',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0x24FFFFFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Sync to Linear
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing || isSynced ? null : _syncToLinear,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isSynced ? Icons.check_circle_rounded : Icons.sync_alt_rounded,
                              size: 15,
                              color: isSynced ? AppColors.tertiary : Colors.white,
                            ),
                      label: Text(
                        _isSyncing
                            ? 'Syncing...'
                            : (isSynced ? 'Linear Synced' : 'Sync to Linear'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSynced ? AppColors.tertiary : Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSynced
                            ? AppColors.tertiary.withValues(alpha: 0.15)
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
