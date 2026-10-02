import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/synapse_logo.dart';
import '../../data/models/meeting.dart';
import '../../providers/meeting_provider.dart';
import '../action_items/action_items_screen.dart';
import '../triage/triage_screen.dart';
import 'widgets/voice_scribe_modal.dart';

/// Screen 1 — Dashboard
/// High-information-density executive operations dashboard matching the Stitch design.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedFilterTab =
      0; // 0: Needs Review, 1: All Meetings, 2: Action Items
  int _selectedNavIndex =
      0; // 0: Dashboard, 1: Meetings, 2: Action Items, 3: Settings
  String? _activeTagFilter;

  // ── Routing helper ────────────────────────────────────────────────────────

  void _openTriage(BuildContext context, {Meeting? meeting}) {
    if (meeting != null) {
      context.read<MeetingProvider>().setActiveMeeting(meeting.id);
    } else {
      context.read<MeetingProvider>().setActiveMeeting(null);
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => TriageScreen(meeting: meeting)),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) {
        final tags = [
          'All',
          '#infrastructure',
          '#budget',
          '#q4',
          '#product',
          '#roadmap',
          '#planning',
          '#security',
          '#audit',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Label',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((t) {
                    final isSelected =
                        (t == 'All' && _activeTagFilter == null) ||
                        _activeTagFilter == t;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _activeTagFilter = t == 'All' ? null : t;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          t,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primaryTint
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeetingProvider>();
    final allMeetings = provider.meetings;

    // Filter by tab
    List<Meeting> filtered = allMeetings;
    if (_selectedFilterTab == 0) {
      filtered = allMeetings
          .where(
            (m) =>
                m.status == MeetingStatus.needsTriage ||
                m.status == MeetingStatus.inProgress,
          )
          .toList();
      if (filtered.isEmpty) filtered = allMeetings;
    }

    // Filter by active tag
    if (_activeTagFilter != null) {
      filtered = filtered
          .where(
            (m) => m.tags.any(
              (t) => t.toLowerCase() == _activeTagFilter!.toLowerCase(),
            ),
          )
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Responsive.constrainedContainer(
          child: Column(
            children: [
              // Sticky Executive Header
              _StitchHeaderBar(
                onSearch: () => _showSnack('Search meetings & transcripts'),
                onNotifications: () =>
                    _showSnack('2 new AI triage notifications'),
                onProfile: () => _showSnack('Muneeb — Engineering Executive'),
              ),

              // Scrollable Dashboard Body
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    // Context & Greeting Header
                    _GreetingSection(
                      processedMeetings: provider.processedMeetings,
                      pendingActions: provider.pendingActionItems,
                    ),
                    const SizedBox(height: 16),

                    // 3-Column Metric KPI Precision Grid
                    _KpiMetricGrid(
                      provider: provider,
                      onTapTotal: () {
                        setState(() => _selectedFilterTab = 1);
                      },
                      onTapProcessed: () {
                        setState(() => _selectedFilterTab = 0);
                      },
                      onTapActions: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ActionItemsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Segmented Control Filter Tabs
                    _SegmentedFilterTabs(
                      selectedIndex: _selectedFilterTab,
                      needsReviewCount: allMeetings
                          .where(
                            (m) =>
                                m.status == MeetingStatus.needsTriage ||
                                m.status == MeetingStatus.inProgress,
                          )
                          .length,
                      onTabChanged: (index) {
                        if (index == 2) {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ActionItemsScreen(),
                            ),
                          );
                        } else {
                          setState(() => _selectedFilterTab = index);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Queue Header with count and filter by label
                    _TriageQueueHeader(
                      count: filtered.length,
                      activeTag: _activeTagFilter,
                      onFilterByLabel: () => _showFilterSheet(context),
                    ),
                    const SizedBox(height: 12),

                    // Meeting Feed Cards
                    if (filtered.isEmpty)
                      _EmptyQueuePlaceholder(
                        onReset: () {
                          setState(() {
                            _activeTagFilter = null;
                            _selectedFilterTab = 1;
                          });
                        },
                      )
                    else
                      ...filtered.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _StitchMeetingCard(
                            meeting: m,
                            onOpenTriage: () =>
                                _openTriage(context, meeting: m),
                            onQuickListen: () => VoiceScribeModal.show(
                              context,
                              meeting: m,
                            ),
                            onExport: () => _showSnack(
                              'Exporting executive digest to Markdown & PDF',
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Instant Scribe Banner — Opens Voice Scribe Modal
                    _InstantScribeBanner(
                      onUpload: () => VoiceScribeModal.show(context),
                    ),
                    const SizedBox(height: 12),

                    // Next Calendar Sync Strip
                    _CalendarGlanceStrip(
                      onViewRoom: () => _showSnack(
                        'Connecting to Executive Sync meeting room...',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _StitchBottomNav(
        selectedIndex: _selectedNavIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ActionItemsScreen(
                  onBackToDashboard: () {
                    Navigator.pop(context);
                    if (mounted) setState(() => _selectedNavIndex = 0);
                  },
                ),
              ),
            ).then((_) {
              if (mounted) setState(() => _selectedNavIndex = 0);
            });
          } else {
            setState(() => _selectedNavIndex = index);
            if (index != 0) {
              final label = [
                'Dashboard',
                'Meetings',
                'Action Items',
                'Settings',
              ][index];
              _showSnack('$label view switched');
            }
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Header Bar
// ─────────────────────────────────────────────────────────────────────────────

class _StitchHeaderBar extends StatelessWidget {
  const _StitchHeaderBar({
    required this.onSearch,
    required this.onNotifications,
    required this.onProfile,
  });

  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Workspace dropdown
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Synapse Brand Logo matching Stitch design
                const SynapseLogo(size: 32),
                const SizedBox(width: 8),
                Text(
                  'Synapse',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 17,
                  color: AppColors.outline,
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.search_rounded, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Search',
                onPressed: onSearch,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                    ),
                    color: AppColors.textSecondary,
                    tooltip: 'Notifications',
                    onPressed: onNotifications,
                  ),
                  Positioned(
                    top: 11,
                    right: 11,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onProfile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: AppColors.onPrimary,
                    ),
                  ),
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
// 2. Greeting & Context Header
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.processedMeetings,
    required this.pendingActions,
  });

  final int processedMeetings;
  final int pendingActions;

  static String _formatDate(DateTime dt) {
    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY'
    ];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return 'TODAY · ${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  static String _greeting(DateTime dt) {
    if (dt.hour < 12) return 'Good morning, Muneeb';
    if (dt.hour < 17) return 'Good afternoon, Muneeb';
    return 'Good evening, Muneeb';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final meetingWord = processedMeetings == 1 ? 'meeting' : 'meetings';
    final actionWord = pendingActions == 1 ? 'action item' : 'action items';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date row & Sync Active indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(now),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.outline,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Sync Active',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Greeting
        Text(
          _greeting(now),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$processedMeetings $meetingWord triaged · $pendingActions $actionWord tracking',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. 3-Column Metric KPI Grid
// ─────────────────────────────────────────────────────────────────────────────

class _KpiMetricGrid extends StatelessWidget {
  const _KpiMetricGrid({
    required this.provider,
    this.onTapTotal,
    this.onTapProcessed,
    this.onTapActions,
  });

  final MeetingProvider provider;
  final VoidCallback? onTapTotal;
  final VoidCallback? onTapProcessed;
  final VoidCallback? onTapActions;

  @override
  Widget build(BuildContext context) {
    final totalMeetings = provider.totalMeetings;
    final totalUnit = totalMeetings == 1 ? 'mtg' : 'mtgs';
    final recordedHoursStr =
        '${provider.recordedHours.toStringAsFixed(1)}h recorded';

    final processedCount = provider.processedMeetings;
    final processedPct = provider.processedPercentage;
    final processedSubtext = provider.processedStatusText;
    final isAllProcessed = processedPct == 100 && totalMeetings > 0;

    final pendingActions = provider.pendingActionItems;
    final dueToday = provider.actionsDueToday;
    final completedActions = provider.completedActionItems;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      child: Row(
        children: [
          // Metric 1: Total
          Expanded(
            child: _KpiCard(
              label: 'Total',
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.outline,
              value: '$totalMeetings',
              unit: totalUnit,
              subtext: recordedHoursStr,
              subtextColor: AppColors.textSecondary,
              onTap: onTapTotal,
            ),
          ),
          const SizedBox(width: 6),

          // Metric 2: Processed
          Expanded(
            child: _KpiCard(
              label: 'Processed',
              icon: Icons.check_circle_rounded,
              iconColor: isAllProcessed ? AppColors.tertiary : AppColors.outline,
              value: '$processedCount',
              unit: '$processedPct%',
              unitColor:
                  isAllProcessed ? AppColors.tertiary : AppColors.outline,
              subtext: processedSubtext,
              subtextColor: isAllProcessed
                  ? AppColors.tertiaryFixedDim
                  : AppColors.textSecondary,
              onTap: onTapProcessed,
            ),
          ),
          const SizedBox(width: 6),

          // Metric 3: Actions
          Expanded(
            child: _KpiCard(
              label: 'Actions',
              icon: Icons.checklist_rounded,
              iconColor: AppColors.primary,
              value: '$pendingActions',
              unit: 'open',
              onTap: onTapActions,
              customFooter: dueToday > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$dueToday due today',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        completedActions > 0
                            ? '$completedActions completed'
                            : 'All caught up',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    this.unitColor,
    this.subtext,
    this.subtextColor,
    this.customFooter,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final Color? unitColor;
  final String? subtext;
  final Color? subtextColor;
  final Widget? customFooter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline,
                    ),
                  ),
                  Icon(icon, size: 14, color: iconColor),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      unit,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: unitColor ?? AppColors.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (customFooter != null)
                customFooter!
              else if (subtext != null)
                Text(
                  subtext!,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: subtextColor ?? AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Segmented Control / Filter Tabs
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentedFilterTabs extends StatelessWidget {
  const _SegmentedFilterTabs({
    required this.selectedIndex,
    required this.needsReviewCount,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final int needsReviewCount;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x10FFFFFF), width: 1),
      ),
      child: Row(
        children: [
          // Tab 0: Needs Review
          Expanded(
            child: _FilterTabButton(
              title: 'Needs Review',
              badgeCount: needsReviewCount,
              isSelected: selectedIndex == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          // Tab 1: All Meetings
          Expanded(
            child: _FilterTabButton(
              title: 'All Meetings',
              isSelected: selectedIndex == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
          // Tab 2: Action Items
          Expanded(
            child: _FilterTabButton(
              title: 'Action Items',
              isSelected: selectedIndex == 2,
              onTap: () => onTabChanged(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabButton extends StatelessWidget {
  const _FilterTabButton({
    required this.title,
    this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Triage Queue Header
// ─────────────────────────────────────────────────────────────────────────────

class _TriageQueueHeader extends StatelessWidget {
  const _TriageQueueHeader({
    required this.count,
    this.activeTag,
    required this.onFilterByLabel,
  });

  final int count;
  final String? activeTag;
  final VoidCallback onFilterByLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(
                Icons.dynamic_feed_rounded,
                size: 13,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Triage Queue',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outline,
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onFilterByLabel,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeTag ?? 'Filter by label',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Rich Meeting Card
// ─────────────────────────────────────────────────────────────────────────────

class _StitchMeetingCard extends StatelessWidget {
  const _StitchMeetingCard({
    required this.meeting,
    required this.onOpenTriage,
    required this.onQuickListen,
    required this.onExport,
  });

  final Meeting meeting;
  final VoidCallback onOpenTriage;
  final VoidCallback onQuickListen;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final statusColor = _resolveStatusColor(meeting.status);
    final priorityColor = _resolvePriorityColor(meeting.priority);
    final accentStripeColor = _resolveStripeColor(
      meeting.priority,
      meeting.status,
    );

    final summary = meeting.triageResult?.summary ?? meeting.description;
    final progressRatio =
        meeting.progressPercent ??
        ((meeting.triageResult?.actionItems.isEmpty ?? true)
            ? 0.0
            : ((meeting.triageResult?.actionItems
                          .where((a) => a.isCompleted)
                          .length ??
                      0) /
                  meeting.triageResult!.actionItems.length));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE616181F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3px Priority Accent Stripe on Left
              Container(width: 3.5, color: accentStripeColor),

              // Card Content Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Title + Priority + Status Tag
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        meeting.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _PriorityDotBadge(
                                      label: meeting.priority.label,
                                      color: priorityColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),

                                // Metadata row
                                Row(
                                  children: [
                                    Text(
                                      meeting.relativeTime ?? 'Today',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Text(
                                        '·',
                                        style: TextStyle(
                                          color: Color(0x33FFFFFF),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${meeting.durationMinutes} min',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Text(
                                        '·',
                                        style: TextStyle(
                                          color: Color(0x33FFFFFF),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.group_outlined,
                                      size: 12,
                                      color: AppColors.outline,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${meeting.participants.length} attendees',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Status Tag (e.g. NEEDS TRIAGE, IN PROGRESS, SYNCED)
                          _StatusTagBadge(
                            label: meeting.status.label,
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // AI Synthesis Snippet
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'AI EXECUTIVE SUMMARY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest
                                  .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0x0AFFFFFF),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              summary,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Semantic Chips
                      if (meeting.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: meeting.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x0AFFFFFF),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0x0FFFFFFF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag.startsWith('#') ? tag : '#$tag',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 10),

                      // Actions Track & Progress Bar
                      _ProgressTrackSection(
                        meeting: meeting,
                        ratio: progressRatio,
                        accentColor: statusColor,
                      ),
                      const SizedBox(height: 12),

                      // Footer Interaction Bar
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0x0EFFFFFF), width: 1),
                          ),
                        ),
                        child: _buildFooterRow(context, meeting),
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

  Widget _buildFooterRow(BuildContext context, Meeting m) {
    if (m.status == MeetingStatus.synced) {
      // Card 3 style: Synced status text + Inspect/Archived buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 14,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: 5),
              Text(
                m.syncStatusText ?? 'Synced to Linear & Jira',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _GhostButton(
                icon: Icons.visibility_outlined,
                label: 'Inspect',
                onTap: onOpenTriage,
              ),
              const SizedBox(width: 6),
              _GhostButton(
                icon: Icons.archive_outlined,
                label: 'Archived',
                onTap: () {},
              ),
            ],
          ),
        ],
      );
    } else if (m.status == MeetingStatus.inProgress) {
      // Card 2 style: Overlapping avatars + View Triage button
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Overlapping Avatar cluster
          Row(
            children: [
              _AttendeeAvatar(initials: 'AL', bg: AppColors.secondaryContainer),
              Transform.translate(
                offset: const Offset(-6, 0),
                child: _AttendeeAvatar(
                  initials: 'SR',
                  bg: AppColors.surfaceBright,
                ),
              ),
              Transform.translate(
                offset: const Offset(-12, 0),
                child: _AttendeeAvatar(
                  initials: '+3',
                  bg: AppColors.surfaceContainerHighest,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onOpenTriage,
            icon: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.tertiary,
            ),
            label: Text(
              'View Triage',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHigh,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0x14FFFFFF)),
              ),
            ),
          ),
        ],
      );
    } else {
      // Card 1 style: Quick listen + export, Details + Review & Approve CTA
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Audio quick listen chip
              InkWell(
                onTap: onQuickListen,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x10FFFFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.graphic_eq_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        m.audioDuration ?? '4:12',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Export button
              InkWell(
                onTap: onExport,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x10FFFFFF)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.ios_share_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _GhostButton(label: 'Details', onTap: onOpenTriage),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: onOpenTriage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Review & Approve',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Color _resolveStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.needsTriage:
        return AppColors.warning;
      case MeetingStatus.inProgress:
        return AppColors.primary;
      case MeetingStatus.synced:
      case MeetingStatus.completed:
        return AppColors.tertiary;
      case MeetingStatus.scheduled:
        return AppColors.accentLight;
      case MeetingStatus.cancelled:
        return AppColors.textMuted;
    }
  }

  Color _resolvePriorityColor(MeetingPriority priority) {
    switch (priority) {
      case MeetingPriority.critical:
        return const Color(0xFFF43F5E); // Rose
      case MeetingPriority.high:
        return AppColors.danger;
      case MeetingPriority.medium:
        return AppColors.secondary;
      case MeetingPriority.low:
        return AppColors.textMuted;
    }
  }

  Color _resolveStripeColor(MeetingPriority priority, MeetingStatus status) {
    if (status == MeetingStatus.synced) return AppColors.tertiary;
    if (priority == MeetingPriority.critical ||
        priority == MeetingPriority.high) {
      return AppColors.danger;
    }
    return AppColors.secondaryContainer;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Priority Chip with Dot Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityDotBadge extends StatelessWidget {
  const _PriorityDotBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4.5,
            height: 4.5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Tag Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusTagBadge extends StatelessWidget {
  const _StatusTagBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Track Section
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressTrackSection extends StatelessWidget {
  const _ProgressTrackSection({
    required this.meeting,
    required this.ratio,
    required this.accentColor,
  });

  final Meeting meeting;
  final double ratio;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final text =
        meeting.progressText ?? '${(ratio * 3).round()} of 3 items drafted';
    final percent = (ratio * 100).round();

    IconData icon;
    Color iconColor;
    if (meeting.status == MeetingStatus.synced) {
      icon = Icons.done_all_rounded;
      iconColor = AppColors.tertiary;
    } else if (meeting.status == MeetingStatus.inProgress) {
      icon = Icons.sync_rounded;
      iconColor = AppColors.primary;
    } else {
      icon = Icons.checklist_rounded;
      iconColor = AppColors.outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: meeting.status == MeetingStatus.synced
                        ? AppColors.tertiary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: meeting.status == MeetingStatus.synced
                    ? AppColors.tertiary
                    : (meeting.status == MeetingStatus.inProgress
                          ? AppColors.primary
                          : AppColors.outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 3,
            width: double.infinity,
            color: const Color(0x0FFFFFFF),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.0, 1.0),
              child: Container(
                color: meeting.status == MeetingStatus.synced
                    ? AppColors.tertiary
                    : (meeting.status == MeetingStatus.inProgress
                          ? AppColors.primaryContainer
                          : AppColors.secondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({this.icon, required this.label, required this.onTap});
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x10FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendeeAvatar extends StatelessWidget {
  const _AttendeeAvatar({required this.initials, required this.bg});
  final String initials;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Instant Scribe Record & Upload Prompt
// ─────────────────────────────────────────────────────────────────────────────

class _InstantScribeBanner extends StatelessWidget {
  const _InstantScribeBanner({required this.onUpload});
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Instant Scribe',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Record real-time or drop audio...',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(
              Icons.add_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            label: Text(
              'Upload',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerHighest,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Cal Integration Strip ("Next: Executive Sync")
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarGlanceStrip extends StatelessWidget {
  const _CalendarGlanceStrip({required this.onViewRoom});
  final VoidCallback onViewRoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x10FFFFFF), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Next: '),
                    TextSpan(
                      text: 'Executive Sync',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: ' in 45m'),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onViewRoom,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'View Room →',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _StitchBottomNav extends StatelessWidget {
  const _StitchBottomNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.space_dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.video_camera_front_rounded, 'Meetings'),
      _NavItem(Icons.task_alt_rounded, 'Action Items'),
      _NavItem(Icons.tune_rounded, 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = selectedIndex == index;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isActive ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyQueuePlaceholder extends StatelessWidget {
  const _EmptyQueuePlaceholder({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x10FFFFFF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'Queue Clear',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All items in this filter are addressed.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onReset,
            child: Text(
              'Reset Filters',
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
