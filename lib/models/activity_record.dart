class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.date,
    required this.activityTypeId,
    required this.activityTypeName,
    required this.count,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final String activityTypeId;
  final String activityTypeName;
  final int count;
  final String content;
  final DateTime createdAt;
}
