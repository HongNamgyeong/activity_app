import '../../models/activity_measure_type.dart';

int activityValueToMinutes(int value, ActivityTimeUnit? timeUnit) {
  if (timeUnit == ActivityTimeUnit.hour) {
    return value * 60;
  }
  return value;
}

String formatRecordValue({
  required int count,
  required ActivityMeasureType measureType,
  ActivityTimeUnit? timeUnit,
}) {
  if (measureType == ActivityMeasureType.count) {
    return '$count회';
  }
  if (timeUnit == ActivityTimeUnit.hour) {
    return '$count시간';
  }
  return '$count분';
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
