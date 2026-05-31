import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import 'app_card.dart';

class DateRangePickerCard extends StatelessWidget {
  const DateRangePickerCard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onSearch,
    this.isLoading = false,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final VoidCallback onSearch;
  final bool isLoading;

  static final _dateFormat = DateFormat('yyyy.MM.dd');

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
              onPrimary: Color(0xFF1E1B4B),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: '시작일',
                  value: startDate == null
                      ? '선택'
                      : _dateFormat.format(startDate!),
                  onTap: () => _pickDate(
                    context,
                    initial: startDate ?? endDate,
                    maxDate: endDate,
                    onChanged: onStartChanged,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ),
              Expanded(
                child: _DateField(
                  label: '종료일',
                  value:
                      endDate == null ? '선택' : _dateFormat.format(endDate!),
                  onTap: () => _pickDate(
                    context,
                    initial: endDate ?? startDate,
                    minDate: startDate,
                    onChanged: onEndChanged,
                  ),
                ),
              ),
            ],
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
                      color: Color(0xFF1E1B4B),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
