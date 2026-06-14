import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../database/app_database.dart';
import '../models/legio_meeting_schedule.dart';
import '../models/time_picker_style.dart';
import 'android_public_backup.dart';
import 'legio_meeting_preferences_service.dart';
import 'time_picker_preferences_service.dart';

enum BackupRestoreResult {
  restored,
  notFound,
  empty,
  upToDate,
  failed,
}

/// 앱 삭제 후 재설치 시에도 기록을 되살리기 위한 로컬 백업·복원.
///
/// - Android: 공용 **다운로드** 폴더(MediaStore) + 앱 내부 사본
/// - iOS: 앱 문서 폴더(재설치 시 삭제됨)
class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  static const _backupVersion = 1;

  /// 복원 중·직후에는 공용 백업 파일을 만들지 않습니다.
  static bool _restoreInProgress = false;
  static DateTime? _suppressPublicWriteUntil;

  Future<File?> _localBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, AppConstants.backupFileName));
  }

  Future<String?> _readBackupContent() async {
    String? bestRaw;
    DateTime? bestExportedAt;

    void consider(String? raw) {
      if (raw == null || raw.isEmpty) return;
      final snapshot = _decodeBackup(raw);
      if (snapshot == null) return;
      if (bestExportedAt == null ||
          snapshot.exportedAt.isAfter(bestExportedAt!)) {
        bestExportedAt = snapshot.exportedAt;
        bestRaw = raw;
      }
    }

    if (Platform.isAndroid) {
      consider(await AndroidPublicBackup.read());
    }

    final local = await _localBackupFile();
    if (local != null && await local.exists()) {
      consider(await local.readAsString());
    }

    return bestRaw;
  }

  Future<bool> _writeBackupContent(String content) async {
    var wroteAny = false;

    if (Platform.isAndroid) {
      wroteAny = await AndroidPublicBackup.write(content) || wroteAny;
    }

    final local = await _localBackupFile();
    if (local != null) {
      await local.parent.create(recursive: true);
      await local.writeAsString(content);
      wroteAny = true;
    }

    return wroteAny;
  }

  Future<void> tryRestoreFromPersistentBackupIfNeeded() async {
    try {
      final raw = await _readBackupContent();
      if (raw == null) return;

      final snapshot = _decodeBackup(raw);
      if (snapshot == null) return;

      if (!await _shouldImportBackup(snapshot)) {
        return;
      }

      final localCount = await _database.activityRecordCount();
      await _database.importBackupData(snapshot);
      await _restoreAppSettings(snapshot);
      debugPrint(
        'BackupService: auto-restored ${snapshot.records.length} records '
        '(local had $localCount)',
      );
    } catch (error, stackTrace) {
      debugPrint('BackupService auto restore failed: $error\n$stackTrace');
    }
  }

  /// 재설치 직후(기록 없음)이거나 백업이 더 많을 때 복원합니다.
  Future<bool> _shouldImportBackup(AppDataBackup snapshot) async {
    if (snapshot.types.isEmpty) return false;

    final localRecords = await _database.activityRecordCount();
    final backupRecords = snapshot.records.length;

    if (backupRecords > 0 && localRecords == 0) {
      return true;
    }
    if (backupRecords > localRecords) {
      return true;
    }
    return false;
  }

  Future<BackupRestoreResult> restoreFromBackupFile({bool force = false}) async {
    _restoreInProgress = true;
    _suppressPublicWriteUntil = DateTime.now().add(const Duration(seconds: 5));
    try {
      final raw = await _readBackupContent();
      if (raw == null) {
        return BackupRestoreResult.notFound;
      }

      final snapshot = _decodeBackup(raw);
      if (snapshot == null) {
        return BackupRestoreResult.failed;
      }

      if (snapshot.types.isEmpty) {
        return BackupRestoreResult.empty;
      }

      if (!force && !await _shouldImportBackup(snapshot)) {
        return BackupRestoreResult.upToDate;
      }

      await _database.importBackupData(snapshot);
      await _restoreAppSettings(snapshot);
      if (Platform.isAndroid) {
        await AndroidPublicBackup.cleanupDuplicates();
      }
      return BackupRestoreResult.restored;
    } catch (error, stackTrace) {
      debugPrint('BackupService restore failed: $error\n$stackTrace');
      return BackupRestoreResult.failed;
    } finally {
      _restoreInProgress = false;
    }
  }

  Future<DateTime?> writeBackup() async {
    if (_restoreInProgress) {
      return null;
    }
    if (_suppressPublicWriteUntil != null &&
        DateTime.now().isBefore(_suppressPublicWriteUntil!)) {
      return null;
    }

    final recordCount = await _database.activityRecordCount();
    if (recordCount == 0) {
      if (Platform.isAndroid && await AndroidPublicBackup.exists()) {
        return lastBackupTime();
      }
      return null;
    }

    final snapshot = await _database.exportBackupData();
    final exportedAt = DateTime.now().toUtc();
    final legioMeetingSchedule = await LegioMeetingPreferencesService.load();
    final recordTimePickerStyle = await TimePickerPreferencesService.loadStyle(
      scope: TimePickerPreferenceScope.record,
    );
    final generalTimePickerStyle = await TimePickerPreferencesService.loadStyle(
      scope: TimePickerPreferenceScope.general,
    );
    final payload = _encodePayload(
      snapshot,
      exportedAt,
      legioMeetingSchedule: legioMeetingSchedule,
      recordTimePickerStyle: recordTimePickerStyle,
      generalTimePickerStyle: generalTimePickerStyle,
    );

    final wrote = await _writeBackupContent(payload);
    if (!wrote) return null;

    if (Platform.isAndroid) {
      await AndroidPublicBackup.cleanupDuplicates();
    }

    return exportedAt.toLocal();
  }

  Future<DateTime?> lastBackupTime() async {
    try {
      final raw = await _readBackupContent();
      if (raw == null) return null;
      return _decodeBackup(raw)?.exportedAt.toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreAppSettings(AppDataBackup snapshot) async {
    if (snapshot.legioMeetingSchedule != null) {
      await LegioMeetingPreferencesService.save(snapshot.legioMeetingSchedule!);
    }

    if (snapshot.recordTimePickerStyle != null) {
      await TimePickerPreferencesService.saveStyle(
        TimePickerStyle.fromStorage(snapshot.recordTimePickerStyle),
        scope: TimePickerPreferenceScope.record,
      );
    }

    if (snapshot.generalTimePickerStyle != null) {
      await TimePickerPreferencesService.saveStyle(
        TimePickerStyle.fromStorage(snapshot.generalTimePickerStyle),
        scope: TimePickerPreferenceScope.general,
      );
    }
  }

  String _encodePayload(
    AppDataBackup snapshot,
    DateTime exportedAt, {
    LegioMeetingSchedule? legioMeetingSchedule,
    TimePickerStyle? recordTimePickerStyle,
    TimePickerStyle? generalTimePickerStyle,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'version': _backupVersion,
      'exportedAt': exportedAt.toIso8601String(),
      if (legioMeetingSchedule != null)
        'legioMeetingSchedule': legioMeetingSchedule.toJson(),
      if (recordTimePickerStyle != null)
        'recordTimePickerStyle': recordTimePickerStyle.storageValue,
      if (generalTimePickerStyle != null)
        'generalTimePickerStyle': generalTimePickerStyle.storageValue,
      'activityTypes': snapshot.types
          .map(
            (type) => {
              'id': type.id,
              'name': type.name,
              'sortOrder': type.sortOrder,
              'measureType': type.measureType,
            },
          )
          .toList(),
      'activityRecords': snapshot.records
          .map(
            (record) => {
              'id': record.id,
              'date': record.date.toIso8601String(),
              'activityTypeId': record.activityTypeId,
              'count': record.count,
              'timeUnit': record.timeUnit,
              'recordTime': record.recordTime,
              'content': record.content,
              'createdAt': record.createdAt.toIso8601String(),
            },
          )
          .toList(),
    });
  }

  AppDataBackup? _decodeBackup(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['version'] != _backupVersion) return null;

    final exportedAtRaw = decoded['exportedAt'] as String?;
    if (exportedAtRaw == null) return null;
    final exportedAt = DateTime.tryParse(exportedAtRaw);
    if (exportedAt == null) return null;

    final typesJson = decoded['activityTypes'];
    final recordsJson = decoded['activityRecords'];
    if (typesJson is! List || recordsJson is! List) return null;

    final types = <BackupActivityType>[];
    for (final item in typesJson) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'] as String?;
      final name = item['name'] as String?;
      final sortOrder = item['sortOrder'] as int?;
      final measureType = item['measureType'] as String? ?? 'count';
      if (id == null || name == null || sortOrder == null) continue;
      types.add(
        BackupActivityType(
          id: id,
          name: name,
          sortOrder: sortOrder,
          measureType: measureType,
        ),
      );
    }

    final records = <BackupActivityRecord>[];
    for (final item in recordsJson) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'] as String?;
      final dateRaw = item['date'] as String?;
      final activityTypeId = item['activityTypeId'] as String?;
      final count = item['count'] as int?;
      final content = item['content'] as String?;
      final createdAtRaw = item['createdAt'] as String?;
      final timeUnit = item['timeUnit'] as String?;
      final recordTime = item['recordTime'] as String?;
      final date = dateRaw == null ? null : DateTime.tryParse(dateRaw);
      final createdAt =
          createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);
      if (id == null ||
          date == null ||
          activityTypeId == null ||
          count == null ||
          content == null ||
          createdAt == null) {
        continue;
      }
      records.add(
        BackupActivityRecord(
          id: id,
          date: DateTime(date.year, date.month, date.day),
          activityTypeId: activityTypeId,
          count: count,
          timeUnit: timeUnit,
          recordTime: recordTime,
          content: content,
          createdAt: createdAt,
        ),
      );
    }

    LegioMeetingSchedule? legioMeetingSchedule;
    final legioJson = decoded['legioMeetingSchedule'];
    if (legioJson is Map<String, dynamic>) {
      legioMeetingSchedule = LegioMeetingSchedule.fromJson(legioJson);
    }

    return AppDataBackup(
      exportedAt: exportedAt,
      types: types,
      records: records,
      legioMeetingSchedule: legioMeetingSchedule,
      recordTimePickerStyle: decoded['recordTimePickerStyle'] as String?,
      generalTimePickerStyle: decoded['generalTimePickerStyle'] as String?,
    );
  }
}
