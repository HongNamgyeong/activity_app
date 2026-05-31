import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../database/app_database.dart';

/// 앱 삭제 후 재설치 시에도 기록을 되살리기 위한 로컬 백업·복원.
///
/// - Android: 공용 다운로드 폴더에 JSON 백업(삭제 후에도 남는 경우가 많음) + OS 자동 백업
/// - iOS: 앱 삭제 시 샌드박스는 지워지므로 iCloud 기기 백업 또는 수동 복원에 의존
class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  static const _backupVersion = 1;

  Future<File?> _resolveBackupFile() async {
    final candidates = <Future<Directory?>>[
      getDownloadsDirectory(),
      getApplicationDocumentsDirectory(),
    ];

    for (final candidate in candidates) {
      final dir = await candidate;
      if (dir == null) continue;
      return File(p.join(dir.path, AppConstants.backupFileName));
    }
    return null;
  }

  Future<void> tryRestoreFromPersistentBackupIfNeeded() async {
    final file = await _resolveBackupFile();
    if (file == null || !await file.exists()) return;

    try {
      final snapshot = _decodeBackup(await file.readAsString());
      if (snapshot == null) return;

      final localCount = await _database.activityRecordCount();
      final backupCount = snapshot.records.length;

      if (backupCount == 0 || localCount >= backupCount) {
        return;
      }

      await _database.importBackupData(snapshot);
      debugPrint(
        'BackupService: restored $backupCount records (local had $localCount)',
      );
    } catch (error, stackTrace) {
      debugPrint('BackupService restore failed: $error\n$stackTrace');
    }
  }

  Future<bool> restoreFromBackupFile({bool force = false}) async {
    final file = await _resolveBackupFile();
    if (file == null || !await file.exists()) {
      return false;
    }

    final snapshot = _decodeBackup(await file.readAsString());
    if (snapshot == null || snapshot.records.isEmpty) {
      return false;
    }

    final localCount = await _database.activityRecordCount();
    if (!force && localCount >= snapshot.records.length) {
      return false;
    }

    await _database.importBackupData(snapshot);
    return true;
  }

  Future<DateTime?> writeBackup() async {
    final file = await _resolveBackupFile();
    if (file == null) return null;

    final snapshot = await _database.exportBackupData();
    final exportedAt = DateTime.now().toUtc();
    final payload = {
      'version': _backupVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'activityTypes': snapshot.types
          .map(
            (type) => {
              'id': type.id,
              'name': type.name,
              'sortOrder': type.sortOrder,
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
              'content': record.content,
              'createdAt': record.createdAt.toIso8601String(),
            },
          )
          .toList(),
    };

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return exportedAt.toLocal();
  }

  Future<DateTime?> lastBackupTime() async {
    final file = await _resolveBackupFile();
    if (file == null || !await file.exists()) return null;

    try {
      final snapshot = _decodeBackup(await file.readAsString());
      return snapshot?.exportedAt.toLocal();
    } catch (_) {
      return null;
    }
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
      if (id == null || name == null || sortOrder == null) continue;
      types.add(
        BackupActivityType(id: id, name: name, sortOrder: sortOrder),
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
          content: content,
          createdAt: createdAt,
        ),
      );
    }

    return AppDataBackup(
      exportedAt: exportedAt,
      types: types,
      records: records,
    );
  }
}
