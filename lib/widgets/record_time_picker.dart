import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/activity_value_format.dart';

class RecordTimePicker extends StatelessWidget {
  const RecordTimePicker({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    this.compact = false,
  });

  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool compact;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.accent,
                onPrimary: AppColors.onAccent,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      onTimeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = formatClockTime(selectedTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '활동 시각',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: compact ? 6 : 8),
        Material(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openPicker(context),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: compact ? 10 : 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: compact ? 18 : 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 15 : null,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
