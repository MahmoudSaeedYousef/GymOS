import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/atoms/gym_card.dart';
import '../../../../core/utils/app_number_format.dart';
import '../../providers/weekly_stats_provider.dart';

/// Metric toggles for the 7-day activity chart.
enum WeeklyChartMetric { attendance, revenue }

/// Compact, executive-grade Material 3 card (~200–220dp height)
/// rendering the Last 7 Days Activity Bar Chart (Attendance & Revenue).
class WeeklyActivityChartCard extends ConsumerStatefulWidget {
  const WeeklyActivityChartCard({super.key});

  @override
  ConsumerState<WeeklyActivityChartCard> createState() =>
      _WeeklyActivityChartCardState();
}

class _WeeklyActivityChartCardState
    extends ConsumerState<WeeklyActivityChartCard> {
  WeeklyChartMetric _selectedMetric = WeeklyChartMetric.attendance;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;
    final locale = Localizations.localeOf(context);
    final statsAsync = ref.watch(weeklyStatsProvider);

    return GymCard(
      elevationLevel: 1,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: statsAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (points) => _buildCardContent(points, colors, locale),
        loading: () => _buildLoadingSkeleton(colors, locale),
        error: (_, _) => _buildEmptyOrFallback(colors, locale),
      ),
    );
  }

  Widget _buildCardContent(
    List<DailyStatPoint> points,
    GymColorsExtension colors,
    Locale locale,
  ) {
    if (points.isEmpty) {
      return _buildEmptyOrFallback(colors, locale);
    }

    // Default to the last point (Today) if not set or out of bounds.
    final selectedIdx = (_selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < points.length)
        ? _selectedIndex!
        : points.length - 1;

    final selectedPoint = points[selectedIdx];
    final isTodaySelected = selectedIdx == points.length - 1;

    // Aggregations
    final totalAttendance =
        points.fold<int>(0, (sum, p) => sum + p.attendanceCount);
    final totalRevenue =
        points.fold<double>(0.0, (sum, p) => sum + p.revenueAmount);

    // Subtitle text: if today is selected, show 7-day total;
    // if another day is tapped, show that day's specific date and value.
    final String subtitleText;
    if (_selectedMetric == WeeklyChartMetric.attendance) {
      if (isTodaySelected) {
        subtitleText = context.l10n.weeklyTotalAttendance(totalAttendance);
      } else {
        final dateStr = _formatFullDate(selectedPoint.date, locale, isToday: false);
        final valStr = '${selectedPoint.attendanceCount} ${context.l10n.attendance}';
        subtitleText = context.l10n.selectedDaySummary(dateStr, valStr);
      }
    } else {
      if (isTodaySelected) {
        final formattedTotal = AppNumberFormat.formatWithCurrency(
          totalRevenue,
          locale: locale.toString(),
          currencySuffix: context.l10n.currency,
        );
        subtitleText = context.l10n.weeklyTotalRevenue(formattedTotal);
      } else {
        final dateStr = _formatFullDate(selectedPoint.date, locale, isToday: false);
        final valStr = AppNumberFormat.formatWithCurrency(
          selectedPoint.revenueAmount,
          locale: locale.toString(),
          currencySuffix: context.l10n.currency,
        );
        subtitleText = context.l10n.selectedDaySummary(dateStr, valStr);
      }
    }

    // Determine max value for proportional bar scaling
    final double maxVal = points.map((p) {
      return _selectedMetric == WeeklyChartMetric.attendance
          ? p.attendanceCount.toDouble()
          : p.revenueAmount;
    }).fold<double>(0.0, (prev, elem) => math.max(prev, elem));

    final bool isAllZero = maxVal <= 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header Row
        _buildHeaderRow(
          colors: colors,
          subtitle: subtitleText,
        ),
        const SizedBox(height: AppSpacing.sm),

        // 2. 7-Day Animated Bar Chart Area
        _buildChartArea(
          points: points,
          selectedIdx: selectedIdx,
          maxVal: maxVal,
          isAllZero: isAllZero,
          colors: colors,
          locale: locale,
        ),
      ],
    );
  }

  Widget _buildHeaderRow({
    required GymColorsExtension colors,
    required String subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & Dynamic Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.last7Days,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  subtitle,
                  key: ValueKey<String>(subtitle),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Compact Pill Toggle
        _MetricPillToggle(
          selectedMetric: _selectedMetric,
          onMetricChanged: (metric) {
            if (_selectedMetric != metric) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedMetric = metric;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildChartArea({
    required List<DailyStatPoint> points,
    required int selectedIdx,
    required double maxVal,
    required bool isAllZero,
    required GymColorsExtension colors,
    required Locale locale,
  }) {
    const double barAreaHeight = 72.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 7 Day Columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(points.length, (index) {
            final point = points[index];
            final isSelected = index == selectedIdx;
            final isToday = index == points.length - 1;

            final double rawValue =
                _selectedMetric == WeeklyChartMetric.attendance
                    ? point.attendanceCount.toDouble()
                    : point.revenueAmount;

            // Height calculation with 5dp flat baseline stub when value is 0
            const double minStubHeight = 5.0;
            final double computedHeight = (maxVal <= 0.0 || rawValue <= 0.0)
                ? minStubHeight
                : (minStubHeight +
                    (rawValue / maxVal) * (barAreaHeight - minStubHeight));

            final String valueLabel =
                _selectedMetric == WeeklyChartMetric.attendance
                    ? '${point.attendanceCount}'
                    : AppNumberFormat.format(point.revenueAmount);

            final String dayLabel = _formatShortWeekday(point.date, locale);

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Value above bar: visible only for selected bar
                    SizedBox(
                      height: 18,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: isSelected ? 1.0 : 0.0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brandPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              valueLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.brandPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Bar with track background
                    Container(
                      width: 22,
                      height: barAreaHeight,
                      decoration: BoxDecoration(
                        color: colors.surfaceLevel2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: 22,
                        height: computedHeight,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.brandPrimary
                              : colors.brandPrimary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Short localized day label
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday
                            ? FontWeight.w800
                            : (isSelected ? FontWeight.w600 : FontWeight.w500),
                        color: isSelected
                            ? colors.brandPrimary
                            : (isToday ? colors.textPrimary : colors.textSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Subtle indicator dot under today
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.brandPrimary
                              : colors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 5),
                  ],
                ),
              ),
            );
          }),
        ),

        // Subtle Empty State Hint Overlay
        if (isAllZero)
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceLevel1.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.surfaceBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                context.l10n.noActivityYet,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(GymColorsExtension colors, Locale locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.last7Days,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 90,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.surfaceLevel2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            _MetricPillToggle(
              selectedMetric: _selectedMetric,
              onMetricChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 22),
                  Container(
                    width: 22,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.surfaceLevel2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 22,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.surfaceBorder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 16,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.surfaceLevel2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyOrFallback(GymColorsExtension colors, Locale locale) {
    final today = DateTime.now();
    final dummyPoints = List.generate(
      7,
      (i) => DailyStatPoint(
        date: DateTime(today.year, today.month, today.day - (6 - i)),
        attendanceCount: 0,
        revenueAmount: 0.0,
      ),
    );
    return _buildCardContent(dummyPoints, colors, locale);
  }

  static String _formatShortWeekday(DateTime date, Locale locale) {
    if (locale.languageCode == 'ar') {
      switch (date.weekday) {
        case DateTime.monday:
          return 'إثنين';
        case DateTime.tuesday:
          return 'ثلاثاء';
        case DateTime.wednesday:
          return 'أربعاء';
        case DateTime.thursday:
          return 'خميس';
        case DateTime.friday:
          return 'جمعة';
        case DateTime.saturday:
          return 'سبت';
        case DateTime.sunday:
          return 'أحد';
        default:
          return '';
      }
    } else {
      switch (date.weekday) {
        case DateTime.monday:
          return 'Mon';
        case DateTime.tuesday:
          return 'Tue';
        case DateTime.wednesday:
          return 'Wed';
        case DateTime.thursday:
          return 'Thu';
        case DateTime.friday:
          return 'Fri';
        case DateTime.saturday:
          return 'Sat';
        case DateTime.sunday:
          return 'Sun';
        default:
          return '';
      }
    }
  }

  static String _formatFullDate(
    DateTime date,
    Locale locale, {
    required bool isToday,
  }) {
    final monthNamesAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final monthNamesEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (locale.languageCode == 'ar') {
      final dayName = switch (date.weekday) {
        DateTime.monday => 'الإثنين',
        DateTime.tuesday => 'الثلاثاء',
        DateTime.wednesday => 'الأربعاء',
        DateTime.thursday => 'الخميس',
        DateTime.friday => 'الجمعة',
        DateTime.saturday => 'السبت',
        DateTime.sunday => 'الأحد',
        _ => '',
      };
      final monthName = monthNamesAr[date.month - 1];
      if (isToday) {
        return 'اليوم، ${date.day} $monthName';
      }
      return '$dayName، ${date.day} $monthName';
    } else {
      final dayName = switch (date.weekday) {
        DateTime.monday => 'Mon',
        DateTime.tuesday => 'Tue',
        DateTime.wednesday => 'Wed',
        DateTime.thursday => 'Thu',
        DateTime.friday => 'Fri',
        DateTime.saturday => 'Sat',
        DateTime.sunday => 'Sun',
        _ => '',
      };
      final monthName = monthNamesEn[date.month - 1];
      if (isToday) {
        return 'Today, $monthName ${date.day}';
      }
      return '$dayName, $monthName ${date.day}';
    }
  }
}

/// Compact pill toggle on the header row to switch between Attendance and Revenue.
class _MetricPillToggle extends StatelessWidget {
  final WeeklyChartMetric selectedMetric;
  final ValueChanged<WeeklyChartMetric> onMetricChanged;

  const _MetricPillToggle({
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.gymColors;

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceLevel2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            context: context,
            metric: WeeklyChartMetric.attendance,
            label: context.l10n.attendance,
            icon: Icons.people_alt_rounded,
            isSelected: selectedMetric == WeeklyChartMetric.attendance,
          ),
          _buildItem(
            context: context,
            metric: WeeklyChartMetric.revenue,
            label: context.l10n.revenue,
            icon: Icons.payments_rounded,
            isSelected: selectedMetric == WeeklyChartMetric.revenue,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required WeeklyChartMetric metric,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final colors = context.gymColors;

    return Material(
      color: isSelected
          ? colors.brandPrimary.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onMetricChanged(metric),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: colors.brandPrimary.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? colors.brandPrimary : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colors.brandPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
