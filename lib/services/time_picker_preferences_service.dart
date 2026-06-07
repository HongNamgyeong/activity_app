import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/time_picker_style.dart';

enum TimePickerPreferenceScope {
  record,
  general,
}

class TimePickerPreferencesService {
  static const _fileName = 'time_picker_prefs.json';
  static const _recordStyleKey = 'recordTimePickerStyle';
  static const _generalStyleKey = 'timePickerStyle';

  static final Map<TimePickerPreferenceScope, TimePickerStyle?> _cachedStyles = {};

  static String _styleKey(TimePickerPreferenceScope scope) {
    return scope == TimePickerPreferenceScope.record
        ? _recordStyleKey
        : _generalStyleKey;
  }

  static TimePickerStyle _defaultStyle(TimePickerPreferenceScope scope) {
    return scope == TimePickerPreferenceScope.record
        ? TimePickerStyle.wheel
        : TimePickerStyle.dial;
  }

  static Future<File> _prefsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<TimePickerStyle> loadStyle({
    TimePickerPreferenceScope scope = TimePickerPreferenceScope.general,
  }) async {
    final cached = _cachedStyles[scope];
    if (cached != null) {
      return cached;
    }

    try {
      final file = await _prefsFile();
      if (!await file.exists()) {
        return _defaultStyle(scope);
      }

      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final raw = data[_styleKey(scope)] as String?;
      final style = raw == null
          ? _defaultStyle(scope)
          : TimePickerStyle.fromStorage(raw);
      _cachedStyles[scope] = style;
      return style;
    } catch (_) {
      return _defaultStyle(scope);
    }
  }

  static Future<void> saveStyle(
    TimePickerStyle style, {
    TimePickerPreferenceScope scope = TimePickerPreferenceScope.general,
  }) async {
    _cachedStyles[scope] = style;

    try {
      final file = await _prefsFile();
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
      data[_styleKey(scope)] = style.storageValue;
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // UI 동작에는 영향 없도록 저장 실패는 무시합니다.
    }
  }
}
