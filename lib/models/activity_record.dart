import 'activity_measure_type.dart';

class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.date,
    required this.activityTypeId,
    required this.activityTypeName,
    required this.count,
    required this.content,
    required this.createdAt,
    this.measureType = ActivityMeasureType.count,
    this.timeUnit,
    this.recordTime,
  });

  final String id;
  final DateTime date;
  final String activityTypeId;
  final String activityTypeName;
  final int count;
  final String content;
  final DateTime createdAt;
  final ActivityMeasureType measureType;
  final ActivityTimeUnit? timeUnit;
  /// 활동 시각 (HH:mm)
  final String? recordTime;
}
