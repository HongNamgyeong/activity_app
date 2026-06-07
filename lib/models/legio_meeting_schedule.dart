import 'package:flutter/material.dart';

import '../core/utils/activity_value_format.dart';

class LegioMeetingSchedule {
  const LegioMeetingSchedule({
    required this.weekday,
    required this.meetingTime,
  });

  /// [DateTime.weekday] 값 (1=월요일 … 7=일요일)
  final int weekday;
  final String meetingTime;

  TimeOfDay get time =>
      parseClockTime(meetingTime) ?? const TimeOfDay(hour: 19, minute: 0);

  static const weekdayLabels = {
    1: '월요일',
    2: '화요일',
    3: '수요일',
    4: '목요일',
    5: '금요일',
    6: '토요일',
    7: '일요일',
  };

  String get weekdayLabel => weekdayLabels[weekday] ?? '수요일';

  String get displayLabel {
    return '$weekdayLabel ${formatClockTime(time)}';
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'meetingTime': meetingTime,
      };

  factory LegioMeetingSchedule.fromJson(Map<String, dynamic> json) {
    final weekday = json['weekday'] as int? ?? 3;
    final meetingTime = json['meetingTime'] as String? ?? '19:00';
    return LegioMeetingSchedule(
      weekday: weekday.clamp(1, 7),
      meetingTime: meetingTime,
    );
  }

  LegioMeetingSchedule copyWith({
    int? weekday,
    String? meetingTime,
  }) {
    return LegioMeetingSchedule(
      weekday: weekday ?? this.weekday,
      meetingTime: meetingTime ?? this.meetingTime,
    );
  }
}
