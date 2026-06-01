import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme/app_colors.dart';

class DateRangeCalendar extends StatelessWidget {
  const DateRangeCalendar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onRangeChanged,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end) onRangeChanged;

  DateTime get _focusedDay => endDate ?? startDate ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 M월 d일');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _DateChip(
                    label: '시작일',
                    value: startDate == null ? '선택' : dateFormat.format(startDate!),
                    selected: startDate != null,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: AppColors.gold, size: 18),
                ),
                Expanded(
                  child: _DateChip(
                    label: '종료일',
                    value: endDate == null ? '선택' : dateFormat.format(endDate!),
                    selected: endDate != null,
                  ),
                ),
              ],
            ),
          ),
          TableCalendar<void>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            locale: 'ko_KR',
            startingDayOfWeek: StartingDayOfWeek.sunday,
            rangeStartDay: startDate,
            rangeEndDay: endDate,
            rangeSelectionMode: RangeSelectionMode.enforced,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.burgundy),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.burgundy),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              weekendStyle: TextStyle(color: AppColors.burgundy, fontSize: 12),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: AppColors.goldMuted.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: AppColors.ink),
              selectedDecoration: const BoxDecoration(
                color: AppColors.burgundy,
                shape: BoxShape.circle,
              ),
              rangeHighlightColor: AppColors.goldMuted.withValues(alpha: 0.35),
              rangeStartDecoration: const BoxDecoration(
                color: AppColors.burgundy,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: AppColors.burgundyDark,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: AppColors.ink),
              weekendTextStyle: const TextStyle(color: AppColors.burgundy),
            ),
            onRangeSelected: (start, end, _) {
              onRangeChanged(start, end);
            },
            onPageChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.selected,
  });

  final String label;
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.goldMuted.withValues(alpha: 0.25)
            : AppColors.parchment,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.gold : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
