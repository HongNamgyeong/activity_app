import 'activity_measure_type.dart';

class ActivityType {
  const ActivityType({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.measureType = ActivityMeasureType.count,
  });

  final String id;
  final String name;
  final int sortOrder;
  final ActivityMeasureType measureType;

  static List<ActivityType> sortedByPriority(List<ActivityType> types) {
    return [...types]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  ActivityType copyWith({
    String? id,
    String? name,
    int? sortOrder,
    ActivityMeasureType? measureType,
  }) {
    return ActivityType(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      measureType: measureType ?? this.measureType,
    );
  }
}
