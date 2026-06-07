import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/activity_record.dart';
import '../../models/legio_meeting_schedule.dart';
import 'activity_value_format.dart';

DateTime recordDateTime(ActivityRecord record) {
  final time = parseClockTime(record.recordTime);
  if (time == null) {
    return DateTime(record.date.year, record.date.month, record.date.day);
  }
  return DateTime(
    record.date.year,
    record.date.month,
    record.date.day,
    time.hour,
    time.minute,
  );
}

bool isRecordInPeriod({
  required ActivityRecord record,
  required DateTime start,
  required DateTime end,
}) {
  final recordAt = recordDateTime(record);
  return !recordAt.isBefore(start) && !recordAt.isAfter(end);
}

/// 기준 시각 이전에 지난 가장 최근 주회 일시
DateTime mostRecentPastLegioMeeting({
  required DateTime reference,
  required LegioMeetingSchedule schedule,
}) {
  var date = DateTime(reference.year, reference.month, reference.day);
  while (date.weekday != schedule.weekday) {
    date = date.subtract(const Duration(days: 1));
  }

  final time = schedule.time;
  var meeting = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );

  if (!meeting.isBefore(reference)) {
    date = date.subtract(const Duration(days: 7));
    meeting = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  return meeting;
}

/// 사용자가 고른 시작일을 설정 요일·시간에 맞게 정렬
DateTime alignStartToLegioMeeting({
  required DateTime pickedDate,
  required LegioMeetingSchedule schedule,
}) {
  var date = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
  while (date.weekday != schedule.weekday) {
    date = date.subtract(const Duration(days: 1));
  }

  final time = schedule.time;
  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String formatDateTimeLabel(DateTime dateTime) {
  final datePart = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(dateTime);
  final timePart = formatClockTime(TimeOfDay.fromDateTime(dateTime));
  return '$datePart $timePart';
}
