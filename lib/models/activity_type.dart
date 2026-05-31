class ActivityType {
  const ActivityType({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  ActivityType copyWith({
    String? id,
    String? name,
    int? sortOrder,
  }) {
    return ActivityType(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
