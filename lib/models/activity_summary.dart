import 'activity_record.dart';

class ActivitySummaryItem {
  const ActivitySummaryItem({
    required this.activityTypeId,
    required this.activityTypeName,
    required this.totalCount,
    required this.recordCount,
    required this.records,
  });

  final String activityTypeId;
  final String activityTypeName;
  final int totalCount;
  final int recordCount;
  final List<ActivityRecord> records;
}

class ActivityPeriodSummary {
  const ActivityPeriodSummary({
    required this.startDate,
    required this.endDate,
    required this.items,
    required this.totalRecords,
    required this.totalCount,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<ActivitySummaryItem> items;
  final int totalRecords;
  final int totalCount;

  bool get isEmpty => items.isEmpty;
}
