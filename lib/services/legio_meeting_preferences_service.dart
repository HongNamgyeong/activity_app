import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/legio_meeting_schedule.dart';

class LegioMeetingPreferencesService {
  static const _fileName = 'legio_meeting_prefs.json';

  static LegioMeetingSchedule? _cached;

  static Future<File> _prefsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<LegioMeetingSchedule?> load() async {
    if (_cached != null) {
      return _cached;
    }

    try {
      final file = await _prefsFile();
      if (!await file.exists()) {
        return null;
      }

      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _cached = LegioMeetingSchedule.fromJson(data);
      return _cached;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(LegioMeetingSchedule schedule) async {
    _cached = schedule;

    try {
      final file = await _prefsFile();
      await file.writeAsString(jsonEncode(schedule.toJson()));
    } catch (_) {
      // 저장 실패는 UI 동작에 영향을 주지 않도록 무시합니다.
    }
  }
}
