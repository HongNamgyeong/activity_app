enum ActivityMeasureType {
  count,
  time;

  String get storageValue => name;

  static ActivityMeasureType fromStorage(String? value) {
    return switch (value) {
      'time' => ActivityMeasureType.time,
      _ => ActivityMeasureType.count,
    };
  }

  String get label => switch (this) {
        ActivityMeasureType.count => '횟수',
        ActivityMeasureType.time => '시간',
      };
}

enum ActivityTimeUnit {
  hour,
  minute;

  String get storageValue => name;

  static ActivityTimeUnit? fromStorage(String? value) {
    return switch (value) {
      'hour' => ActivityTimeUnit.hour,
      'minute' => ActivityTimeUnit.minute,
      _ => null,
    };
  }

  String get label => switch (this) {
        ActivityTimeUnit.hour => '시',
        ActivityTimeUnit.minute => '분',
      };
}
