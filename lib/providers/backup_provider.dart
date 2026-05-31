import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_service.dart';
import 'database_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

Future<void> scheduleDataBackup(Ref ref) async {
  try {
    await ref.read(backupServiceProvider).writeBackup();
  } catch (_) {
    // 백업 실패는 앱 사용을 막지 않습니다.
  }
}
