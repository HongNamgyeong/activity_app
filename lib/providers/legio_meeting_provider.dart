import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/legio_meeting_schedule.dart';
import '../services/legio_meeting_preferences_service.dart';

final legioMeetingScheduleProvider =
    NotifierProvider<LegioMeetingNotifier, LegioMeetingSchedule?>(
  LegioMeetingNotifier.new,
);

class LegioMeetingNotifier extends Notifier<LegioMeetingSchedule?> {
  @override
  LegioMeetingSchedule? build() => null;

  Future<void> load() async {
    state = await LegioMeetingPreferencesService.load();
  }

  Future<void> save(LegioMeetingSchedule schedule) async {
    await LegioMeetingPreferencesService.save(schedule);
    state = schedule;
  }
}
