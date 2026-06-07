import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/time_picker_style.dart';
import '../services/time_picker_preferences_service.dart';

Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TimePickerPreferenceScope scope = TimePickerPreferenceScope.general,
}) async {
  var style = await TimePickerPreferencesService.loadStyle(scope: scope);
  var time = initialTime;

  if (!context.mounted) {
    return null;
  }

  while (context.mounted) {
    if (style == TimePickerStyle.dial) {
      final outcome = await _showDialPicker(context, time);
      if (!context.mounted) {
        return null;
      }
      if (outcome == null) {
        return null;
      }
      if (outcome.switchTo != null) {
        style = outcome.switchTo!;
        if (outcome.time != null) {
          time = outcome.time!;
        }
        await TimePickerPreferencesService.saveStyle(style, scope: scope);
        continue;
      }
      if (outcome.time != null) {
        await TimePickerPreferencesService.saveStyle(
          TimePickerStyle.dial,
          scope: scope,
        );
        return outcome.time;
      }
      return null;
    }

    final outcome = await _showWheelPicker(context, time);
    if (!context.mounted) {
      return null;
    }
    if (outcome == null) {
      return null;
    }
    if (outcome.switchTo != null) {
      style = outcome.switchTo!;
      if (outcome.time != null) {
        time = outcome.time!;
      }
      await TimePickerPreferencesService.saveStyle(style, scope: scope);
      continue;
    }
    if (outcome.time != null) {
      await TimePickerPreferencesService.saveStyle(
        TimePickerStyle.wheel,
        scope: scope,
      );
      return outcome.time;
    }
    return null;
  }

  return null;
}

class _PickerOutcome {
  const _PickerOutcome({this.time, this.switchTo});

  final TimeOfDay? time;
  final TimePickerStyle? switchTo;
}

Future<_PickerOutcome?> _showDialPicker(
  BuildContext context,
  TimeOfDay initialTime,
) async {
  TimePickerStyle? switchTo;

  final picked = await showDialog<TimeOfDay>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('활동 시각'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StyleSelector(
                selected: TimePickerStyle.dial,
                onSelected: (style) {
                  if (style == TimePickerStyle.wheel) {
                    switchTo = TimePickerStyle.wheel;
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              const SizedBox(height: 12),
              MediaQuery(
                data: MediaQuery.of(dialogContext)
                    .copyWith(alwaysUse24HourFormat: true),
                child: Theme(
                  data: Theme.of(dialogContext).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.accent,
                      onPrimary: AppColors.onAccent,
                      surface: AppColors.surface,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: TimePickerDialog(
                    initialTime: initialTime,
                    initialEntryMode: TimePickerEntryMode.dialOnly,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (switchTo != null) {
    return _PickerOutcome(switchTo: switchTo);
  }
  if (picked != null) {
    return _PickerOutcome(time: picked);
  }
  return null;
}

Future<_PickerOutcome?> _showWheelPicker(
  BuildContext context,
  TimeOfDay initialTime,
) {
  return showDialog<_PickerOutcome>(
    context: context,
    builder: (dialogContext) => _WheelTimePickerDialog(initialTime: initialTime),
  );
}

class _WheelTimePickerDialog extends StatefulWidget {
  const _WheelTimePickerDialog({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_WheelTimePickerDialog> createState() => _WheelTimePickerDialogState();
}

class _WheelTimePickerDialogState extends State<_WheelTimePickerDialog> {
  late DateTime _selectedDateTime = _timeToDateTime(widget.initialTime);

  static DateTime _timeToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  static TimeOfDay _dateTimeToTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('활동 시각'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StyleSelector(
              selected: TimePickerStyle.wheel,
              onSelected: (style) {
                if (style == TimePickerStyle.dial) {
                  Navigator.of(context).pop(
                    _PickerOutcome(
                      switchTo: TimePickerStyle.dial,
                      time: _dateTimeToTime(_selectedDateTime),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  primaryColor: AppColors.accent,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: _selectedDateTime,
                  onDateTimeChanged: (dateTime) {
                    setState(() => _selectedDateTime = dateTime);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _PickerOutcome(time: _dateTimeToTime(_selectedDateTime)),
            );
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _StyleSelector extends StatelessWidget {
  const _StyleSelector({
    required this.selected,
    required this.onSelected,
  });

  final TimePickerStyle selected;
  final ValueChanged<TimePickerStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TimePickerStyle>(
      segments: const [
        ButtonSegment(
          value: TimePickerStyle.dial,
          label: Text('다이얼'),
          icon: Icon(Icons.access_time),
        ),
        ButtonSegment(
          value: TimePickerStyle.wheel,
          label: Text('스크롤'),
          icon: Icon(Icons.unfold_more),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}
