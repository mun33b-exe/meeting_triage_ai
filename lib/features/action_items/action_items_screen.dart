import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/action_item.dart';
import '../../providers/meeting_provider.dart';
import '../triage/triage_screen.dart';

/// Company-wide Cross-Meeting Action Items Screen.
/// Aggregates all tasks across all meetings with filtering and instant toggles.
class ActionItemsScreen extends StatefulWidget {
  const ActionItemsScreen({super.key, this.onBackToDashboard});

  final VoidCallback? onBackToDashboard;

  @override
  State<ActionItemsScreen> createState() => _ActionItemsScreenState();
}

class _ActionItemsScreenState extends State<ActionItemsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Critical/High, 2: Due Today, 3: Completed

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeetingProvider>();
    final allItems = provider.allActionItems;

    // Filter logic
    List<ActionItem> filtered;
    switch (_selectedFilterIndex) {
      case 1:
        // High / Critical priority
        filtered = allItems
            .where((a) => !a.isCompleted && a.priority == ActionPriority.high)
            .toList();
        break;
      case 2:
        // Due today or high urgency
        filtered = allItems.where((a) => !a.isCompleted && (a.isDueToday || a.priority == ActionPriority.high)).toList();
        break;
      case 3:
        // Completed items
        filtered = allItems.where((a) => a.isCompleted).toList();
        break;
      case 0:
      default:
        // All active tasks
        filtered = allItems.where((a) => !a.isCompleted).toList();
        break;
    }

    final openCount = allItems.where((a) => !a.isCompleted).length;
    final highCount = allItems.where((a) => !a.isCompleted && a.priority == ActionPriority.high).length;
    final dueTodayCount = provider.actionsDueToday;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Responsive.constrainedContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              _ActionItemsHeader(
                onBack: widget.onBackToDashboard,
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All ($openCount)',
                        isSelected: _selectedFilterIndex == 0,
                        onTap: () => setState(() => _selectedFilterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Critical / High ($highCount)',
                        isSelected: _selectedFilterIndex == 1,
                        color: AppColors.danger,
                        onTap: () => setState(() => _selectedFilterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Due Today ($dueTodayCount)',
                        isSelected: _selectedFilterIndex == 2,
                        color: AppColors.warning,
                        onTap: () => setState(() => _selectedFilterIndex = 2),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        isSelected: _selectedFilterIndex == 3,
                        color: AppColors.tertiary,
                        onTap: () => setState(() => _selectedFilterIndex = 3),
                      ),
                    ],
                  ),
                ),
              ),

              // Overview Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.task_alt_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cross-Meeting Action Tracker',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${provider.completedActionItems} completed · $openCount open across ${provider.totalMeetings} meetings',
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
              ),

              // Task List
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyTasksView(
                        isCompletedView: _selectedFilterIndex == 3,
                        onClearFilter: () => setState(() => _selectedFilterIndex = 0),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _TaskCard(
                            item: item,
                            onToggle: () {
                              provider.toggleActionItem(item.meetingId, item.id);
                            },
                            onViewMeeting: () {
                              final meeting = provider.meetings.firstWhere(
                                (m) => m.id == item.meetingId,
                                orElse: () => provider.meetings.first,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => TriageScreen(meeting: meeting),
                                ),
                              );
                            },
                          );
                        },
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
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ActionItemsHeader extends StatelessWidget {
  const _ActionItemsHeader({this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (onBack != null) const SizedBox(width: 8),
              Text(
                'Action Items',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_alt_rounded,
                    size: 13, color: AppColors.tertiary),
                const SizedBox(width: 4),
                Text(
                  'Synced to Linear',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tertiary,
                  ),
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
// Task Card
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.item,
    required this.onToggle,
    required this.onViewMeeting,
  });

  final ActionItem item;
  final VoidCallback onToggle;
  final VoidCallback onViewMeeting;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'No due date';
    return DateFormat('MMM d').format(dt);
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
    final (priorityColor, priorityBg) = switch (item.priority) {
      ActionPriority.high => (AppColors.danger, AppColors.danger.withValues(alpha: 0.15)),
      ActionPriority.medium => (AppColors.warning, AppColors.warning.withValues(alpha: 0.15)),
      ActionPriority.low => (AppColors.success, AppColors.success.withValues(alpha: 0.15)),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isCompleted ? const Color(0x0EFFFFFF) : const Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Meeting Tag
          if (item.meetingTitle != null) ...[
            InkWell(
              onTap: onViewMeeting,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 12, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item.meetingTitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryTint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.outline),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Title + Checkbox row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Interactive checkbox
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
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
                          size: 12, color: Colors.black)
                      : null,
                ),
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: GestureDetector(
                  onTap: onToggle,
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: item.isCompleted
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: item.isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metadata row: Assignee avatar + Priority badge + Due date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Assignee with Avatar initials
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x20FFFFFF)),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(item.assignedTo),
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
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
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Badges
              Row(
                children: [
                  // Due date chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isDueToday
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 10.5,
                          color: item.isDueToday
                              ? AppColors.warning
                              : AppColors.outline,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.isDueToday ? 'Today' : _formatDate(item.dueDate),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: item.isDueToday
                                ? AppColors.warning
                                : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: priorityColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.priorityLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.18)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? activeColor
                : const Color(0x14FFFFFF),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTasksView extends StatelessWidget {
  const _EmptyTasksView({
    required this.isCompletedView,
    required this.onClearFilter,
  });

  final bool isCompletedView;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.done_all_rounded,
                size: 28,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCompletedView
                  ? 'No completed tasks yet'
                  : 'All caught up! Zero pending actions',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isCompletedView
                  ? 'Check off action items from meeting triages.'
                  : 'Every action item has been executed and verified.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearFilter,
              child: Text(
                'Show All Active Tasks',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
