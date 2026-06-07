import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/activity_measure_type.dart';

int activityValueToMinutes(int value, ActivityTimeUnit? timeUnit) {
  if (timeUnit == ActivityTimeUnit.hour) {
    return value * 60;
  }
  return value;
}

/// 횟수 단위. 묵주기도는 「단」, 그 외는 「회」.
String countUnitLabel(String? activityTypeName) {
  final name = activityTypeName?.trim() ?? '';
  if (name == '묵주기도' || name.contains('묵주기도')) {
    return '단';
  }
  return '회';
}

String formatCountValue(int count, {String? activityTypeName}) {
  return '$count${countUnitLabel(activityTypeName)}';
}

String formatRecordValue({
  required int count,
  required ActivityMeasureType measureType,
  ActivityTimeUnit? timeUnit,
  String? activityTypeName,
}) {
  if (measureType == ActivityMeasureType.count) {
    return formatCountValue(count, activityTypeName: activityTypeName);
  }
  if (timeUnit == ActivityTimeUnit.hour) {
    return '$count시간';
  }
  return '$count분';
}

String formatClockTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? parseClockTime(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String formatRecordDateLabel(DateTime date, {String? recordTime}) {
  final datePart = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(date);
  if (recordTime == null || recordTime.isEmpty) {
    return datePart;
  }
  return '$datePart $recordTime';
}

String formatTotalTimeValue(int totalMinutes) {
  if (totalMinutes <= 0) {
    return '0분';
  }
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) {
    return '$hours시간 $minutes분';
  }
  if (hours > 0) {
    return '$hours시간';
  }
  return '$minutes분';
}
