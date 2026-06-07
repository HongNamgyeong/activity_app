import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/inquiry_period_utils.dart';
import '../models/legio_meeting_schedule.dart';
import 'app_card.dart';
import 'app_time_picker_dialog.dart';

class DateRangePickerCard extends StatelessWidget {
  const DateRangePickerCard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onStartTimeChanged,
    required this.onEndDateChanged,
    required this.onEndTimeChanged,
    required this.onSearch,
    this.legioSchedule,
    this.onResetStartToLegio,
    this.isLoading = false,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final VoidCallback onSearch;
  final LegioMeetingSchedule? legioSchedule;
  final VoidCallback? onResetStartToLegio;
  final bool isLoading;

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime? initial,
    DateTime? minDate,
    DateTime? maxDate,
    required ValueChanged<DateTime> onChanged,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: minDate ?? DateTime(2020),
      lastDate: maxDate ?? DateTime(2035),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: AppColors.onAccent,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  Future<void> _pickTime(
    BuildContext context, {
    required DateTime? base,
    required ValueChanged<TimeOfDay> onChanged,
  }) async {
    if (base == null) return;

    final picked = await showAppTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '조회 기간 설정',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.calendar_month_outlined,
                color: AppColors.textMuted.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          if (legioSchedule != null) ...[
            const SizedBox(height: 8),
            Text(
              '시작일시 기본값: 가장 최근 지난 ${legioSchedule!.displayLabel}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          _DateTimeField(
            label: '시작',
            dateValue: startDate == null
                ? '날짜 선택'
                : formatDateTimeLabel(startDate!),
            onDateTap: () => _pickDate(
              context,
              initial: startDate ?? endDate,
              maxDate: endDate,
              onChanged: onStartDateChanged,
            ),
            showTime: startDate != null,
            onTimeTap: startDate == null
                ? null
                : () => _pickTime(
                      context,
                      base: startDate,
                      onChanged: onStartTimeChanged,
                    ),
          ),
          if (legioSchedule != null && onResetStartToLegio != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onResetStartToLegio,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('주회시간 기준으로 맞추기'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _DateTimeField(
            label: '종료',
            dateValue: endDate == null
                ? '날짜 선택'
                : formatDateTimeLabel(endDate!),
            onDateTap: () => _pickDate(
              context,
              initial: endDate ?? startDate,
              minDate: startDate,
              onChanged: onEndDateChanged,
            ),
            showTime: endDate != null,
            onTimeTap: endDate == null
                ? null
                : () => _pickTime(
                      context,
                      base: endDate,
                      onChanged: onEndTimeChanged,
                    ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isLoading ? null : onSearch,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onAccent,
                    ),
                  )
                : const Icon(Icons.search, size: 20),
            label: Text(isLoading ? '조회 중...' : '조회하기'),
          ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.dateValue,
    required this.onDateTap,
    this.showTime = false,
    this.onTimeTap,
  });

  final String label;
  final String dateValue;
  final VoidCallback onDateTap;
  final bool showTime;
  final VoidCallback? onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onDateTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateValue,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (showTime && onTimeTap != null)
                TextButton.icon(
                  onPressed: onTimeTap,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('시간'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
